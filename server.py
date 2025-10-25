"""
FastAPI Document Classification Service
Modern OCR-based document classification with parallel processing
"""

import asyncio
import io
import os
import sys
import tempfile
import zipfile
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from enum import Enum
from pathlib import Path
from typing import Annotated

# Set paths before importing pytesseract
if sys.platform == "win32":
    os.environ["TESSDATA_PREFIX"] = r"C:\tools\tesseract\tessdata"
    import pytesseract

    pytesseract.pytesseract.tesseract_cmd = r"C:\tools\tesseract\tesseract.exe"
else:
    os.environ["TESSDATA_PREFIX"] = os.getenv(
        "TESSDATA_PREFIX", "/usr/share/tesseract-ocr/5/tessdata/"
    )
    import pytesseract

    pytesseract.pytesseract.tesseract_cmd = "tesseract"

import logging
from concurrent.futures import ThreadPoolExecutor
from functools import lru_cache

import aiofiles
import pytesseract
from fastapi import (
    FastAPI,
    File,
    Form,
    HTTPException,
    Query,
    Request,
    UploadFile,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from pdf2image import convert_from_bytes
from PIL import Image
from pydantic import BaseModel, ConfigDict, Field, validator
from pydantic_settings import BaseSettings


# Configuration
class Settings(BaseSettings):
    """Application settings with environment variable support"""

    max_file_size: int = Field(
        default=50 * 1024 * 1024, description="Max file size in bytes"
    )
    max_request_size: int = Field(
        default=500 * 1024 * 1024, description="Max request size in bytes"
    )
    max_workers: int = Field(
        default=min(4, os.cpu_count() or 1), description="Thread pool workers"
    )
    upload_folder: Path = Field(default=Path("uploads"), description="Upload directory")
    web_build_folder: Path = Field(
        default=Path("build/web"), description="Flutter web build directory"
    )
    max_pages_ocr: int = Field(default=10, description="Max PDF pages to OCR")
    image_max_size: int = Field(default=2000, description="Max image dimension for OCR")
    log_level: str = Field(default="INFO", description="Logging level")

    model_config = ConfigDict(env_prefix="APP_", case_sensitive=False)


settings = Settings()

# Setup logging
logging.basicConfig(
    level=getattr(logging, settings.log_level),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


# Document categories and keywords
class DocumentCategory(str, Enum):
    UDOSTOVERENIE = "Udostoverenie"
    ENT = "ENT"
    LGOTA = "Lgota"
    DIPLOM = "Diplom"
    PRIVIVKA = "Privivka"
    MED_SPRAVKA = "MedSpravka"
    UNCLASSIFIED = "Unclassified"


CATEGORY_KEYWORDS = {
    DocumentCategory.UDOSTOVERENIE: ["удостоверение", "ID"],
    DocumentCategory.ENT: [
        "сертификат",
        "ТЕСТИРОВАНИЯ",
        "ТЕСТІЛЕУ",
        "ТЕСТИРУЕМОГО",
        "Набранные баллы",
    ],
    DocumentCategory.LGOTA: ["льгота", "инвалид", "многодетная"],
    DocumentCategory.DIPLOM: ["диплом", "аттестат", "бакалавр", "магистр"],
    DocumentCategory.PRIVIVKA: [
        "прививка",
        "прививочный паспорт",
        "вакцинирование",
        "инфекция",
    ],
    DocumentCategory.MED_SPRAVKA: [
        "медицинская справка",
        "справка",
        "медицинский",
        "туберкулез",
        "полиомелит",
        "гепатит",
        "вич",
        "спид",
        "карта ребенка",
        "Дегельминтизация",
        "дегельминтизация",
        "клинический анализ крови",
        "анализ крови",
        "анализ мочи",
        "моча",
        "кровь",
        "флюорография",
        "флюорографическое обследование",
        "флюорография легких",
    ],
}

ALLOWED_EXTENSIONS = {".pdf", ".jpg", ".jpeg", ".png"}
ALLOWED_MIMETYPES = {
    "application/pdf",
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/pjpeg",
}


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """Manage application lifecycle"""

    # Startup
    settings.upload_folder.mkdir(exist_ok=True)
    app.state.executor = ThreadPoolExecutor(max_workers=settings.max_workers)
    logger.info("Started ThreadPoolExecutor with %d workers", settings.max_workers)

    yield

    # Shutdown
    executor = getattr(app.state, "executor", None)
    if executor:
        executor.shutdown(wait=True)
        logger.info("Shut down ThreadPoolExecutor")


# FastAPI application
app = FastAPI(
    title="AI Reception",
    description="OCR-based document classification with parallel processing",
    version="2.0.0",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Pydantic models
class ProcessedFile(BaseModel):
    """Response model for processed file"""

    original_name: str
    # Return stable string keys so frontend can rely on exact values
    category: str
    new_name: str | None = None


class FileDeleteResponse(BaseModel):
    """Response model for file deletion"""

    status: str
    filename: str


class HealthCheck(BaseModel):
    """Health check response"""

    status: str
    version: str


# Utility functions
def validate_file_extension(filename: str) -> bool:
    """Validate file extension"""
    return Path(filename).suffix.lower() in ALLOWED_EXTENSIONS


def validate_mimetype(content_type: str) -> bool:
    """Validate MIME type"""
    return content_type in ALLOWED_MIMETYPES


def sanitize_name(name: str) -> str:
    """Sanitize name for filesystem usage"""
    if not name:
        return "anon"
    safe = "".join(c for c in name if c.isalnum() or c in ("_", "-"))
    return safe or "anon"


def optimize_image(img: Image.Image, max_size: int | None = None) -> Image.Image:
    """Resize image to improve OCR speed while maintaining quality"""
    max_size = max_size or settings.image_max_size
    if max(img.size) > max_size:
        img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
    return img


def extract_text(file_bytes: bytes, ext: str) -> str:
    """
    Extract text from document using OCR
    Optimizations:
    - Only process first few pages of PDFs
    - Resize images for faster OCR
    - Use faster OCR config
    """
    ocr_config = "--psm 3 --oem 1"  # Faster OCR mode

    if ext == ".pdf":
        images = convert_from_bytes(
            file_bytes, first_page=1, last_page=settings.max_pages_ocr
        )
        texts = []
        for image in images:
            optimized = optimize_image(image)
            text = pytesseract.image_to_string(optimized, lang="rus", config=ocr_config)
            texts.append(text)

            # Early exit if we have enough text for classification
            combined = "\n".join(texts)
            if len(combined) > 500:
                break
        return "\n".join(texts)
    img = Image.open(io.BytesIO(file_bytes))
    img = optimize_image(img)
    return pytesseract.image_to_string(img, lang="rus", config=ocr_config)


@lru_cache(maxsize=256)
def classify_text(text: str) -> DocumentCategory:
    """Classify text based on keywords with caching"""
    text_lower = text.lower()
    best_match = DocumentCategory.UNCLASSIFIED
    max_hits = 0

    for category, keywords in CATEGORY_KEYWORDS.items():
        hits = sum(1 for keyword in keywords if keyword.lower() in text_lower)
        if hits > max_hits:
            max_hits = hits
            best_match = category
            logger.debug(
                "Category: %s, Hits: %d, Keywords: %s",
                category,
                hits,
                [k for k in keywords if k.lower() in text_lower],
            )

    return best_match


def generate_unique_filename(
    name: str, lastname: str, category: DocumentCategory, ext: str
) -> str:
    """Generate unique filename with incrementing counter"""
    base_name = f"{sanitize_name(name)}_{sanitize_name(lastname)}_{category.value}"

    index = 1
    while True:
        candidate = f"{base_name}{index}{ext}"
        path = settings.upload_folder / candidate
        if not path.exists():
            return candidate
        index += 1


def _raise_file_too_large(filename: str) -> None:
    """Helper that raises a 413 HTTPException for an oversized file."""
    raise HTTPException(
        status_code=413,
        detail=f"File {filename} exceeds size limit",
    )


async def process_single_file(
    file_data: tuple[str, Path], name: str, lastname: str, executor: ThreadPoolExecutor
) -> ProcessedFile | None:
    """
    Process a single file - runs OCR in thread pool

    Args:
        file_data: Tuple of (original_name, temp_path)
        name: User's first name
        lastname: User's last name

    Returns:
        ProcessedFile or None if processing failed
    """
    original_name, tmp_path = file_data
    ext = Path(original_name).suffix.lower()

    if not validate_file_extension(original_name):
        tmp_path.unlink(missing_ok=True)
        return None

    try:
        # Read file bytes asynchronously to avoid blocking
        async with aiofiles.open(tmp_path, "rb") as afp:
            file_bytes = await afp.read()

        # Run CPU-bound OCR in thread pool
        loop = asyncio.get_running_loop()
        text = await loop.run_in_executor(executor, extract_text, file_bytes, ext)

        # Classify document
        category = classify_text(text)

        new_name = None
        if category != DocumentCategory.UNCLASSIFIED:
            new_name = generate_unique_filename(name, lastname, category, ext)
            dest_path = settings.upload_folder / new_name
            # write asynchronously
            async with aiofiles.open(dest_path, "wb") as dfp:
                await dfp.write(file_bytes)

        return ProcessedFile(
            original_name=original_name, category=category.value, new_name=new_name
        )
    except Exception:
        logger.exception("Error processing file %s", original_name)
        return None
    finally:
        tmp_path.unlink(missing_ok=True)


async def _save_upload_to_tmp(upload_file: UploadFile) -> tuple[str, Path] | None:
    """Validate and save an UploadFile to a temporary path asynchronously.

    Returns (original_filename, tmp_path) or None if rejected.
    """
    if not upload_file.filename:
        return None

    if not validate_file_extension(upload_file.filename):
        logger.warning("Rejected disallowed file type: %s", upload_file.filename)
        return None

    if upload_file.content_type and not validate_mimetype(upload_file.content_type):
        logger.warning(
            "Rejected unexpected content-type %s for %s",
            upload_file.content_type,
            upload_file.filename,
        )
        return None

    tmp_fd, tmp_path_str = tempfile.mkstemp(
        prefix="upload_", suffix=Path(upload_file.filename).suffix
    )
    os.close(tmp_fd)
    tmp_path = Path(tmp_path_str)

    try:
        total_size = 0
        async with aiofiles.open(tmp_path, "wb") as afp:
            while chunk := await upload_file.read(8192):
                total_size += len(chunk)
                if total_size > settings.max_file_size:
                    tmp_path.unlink(missing_ok=True)
                    _raise_file_too_large(upload_file.filename)
                await afp.write(chunk)
    except HTTPException:
        raise
    except Exception as e:
        tmp_path.unlink(missing_ok=True)
        logger.exception("Error saving %s", upload_file.filename)
        raise HTTPException(
            status_code=400,
            detail="Failed to save uploaded file",
        ) from e
    else:
        return (upload_file.filename, tmp_path)


# API endpoints
@app.get("/health", response_model=HealthCheck)
async def health_check() -> HealthCheck:
    """Health check endpoint"""
    return HealthCheck(status="healthy", version="2.0.0")


@app.post("/upload", response_model=list[ProcessedFile])
async def upload_files(
    request: Request,
    name: Annotated[str, Form(min_length=1, max_length=100)],
    lastname: Annotated[str, Form(min_length=1, max_length=100)],
    files: Annotated[list[UploadFile], File()],
) -> list[ProcessedFile]:
    """
    Upload and classify documents

    - **name**: User's first name
    - **lastname**: User's last name
    - **files**: List of documents (PDF, JPG, PNG)
    """
    if not files:
        raise HTTPException(status_code=400, detail="No files provided")

    # Validate and save files to temporary locations
    file_data_list = await _gather_file_data(files)

    if not file_data_list:
        raise HTTPException(status_code=400, detail="No valid files uploaded")

    try:
        executor = request.app.state.executor
        processed_files = await _process_files(file_data_list, name, lastname, executor)

        logger.info("Successfully processed %d files", len(processed_files))
        return processed_files
    finally:
        # Cleanup temporary files
        for _, tmp_path in file_data_list:
            tmp_path.unlink(missing_ok=True)


async def _process_files(
    file_data_list: list[tuple[str, Path]],
    name: str,
    lastname: str,
    executor: ThreadPoolExecutor,
) -> list[ProcessedFile]:
    """Run processing tasks concurrently and return successful results."""
    tasks = [
        process_single_file(file_data, name, lastname, executor)
        for file_data in file_data_list
    ]
    results = await asyncio.gather(*tasks)
    return [r for r in results if r is not None]


async def _gather_file_data(files: list[UploadFile]) -> list[tuple[str, Path]]:
    """Validate and save all uploaded files, returning list of (name, tmp_path)."""
    results: list[tuple[str, Path]] = []
    for upload_file in files:
        if not upload_file.filename:
            continue

        saved = await _save_upload_to_tmp(upload_file)
        if saved:
            results.append(saved)
    return results


@app.get("/files/{filename}")
async def download_file(filename: str) -> FileResponse:
    """Download a specific file"""
    file_path = settings.upload_folder / filename

    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File not found")

    # Security: Prevent directory traversal
    if not file_path.resolve().parent == settings.upload_folder.resolve():
        raise HTTPException(status_code=403, detail="Access denied")

    return FileResponse(
        path=file_path, filename=filename, media_type="application/octet-stream"
    )


@app.get("/download_zip")
async def download_zip(
    name: Annotated[str, Query(min_length=1)],
    lastname: Annotated[str, Query(min_length=1)],
) -> StreamingResponse:
    """Download all files for a user as ZIP"""
    prefix = f"{sanitize_name(name)}_{sanitize_name(lastname)}_"

    # Create ZIP in memory
    zip_buffer = io.BytesIO()
    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as archive:
        for file_path in settings.upload_folder.glob(f"{prefix}*"):
            if file_path.is_file():
                archive.write(file_path, arcname=file_path.name)

    zip_buffer.seek(0)

    return StreamingResponse(
        zip_buffer,
        media_type="application/zip",
        headers={"Content-Disposition": "attachment; filename=documents.zip"},
    )


@app.delete("/delete_file", response_model=FileDeleteResponse)
async def delete_file(filename: Annotated[str, Query()]) -> FileDeleteResponse:
    """Delete a specific file"""
    file_path = settings.upload_folder / filename

    # Security: Prevent directory traversal
    if not file_path.resolve().parent == settings.upload_folder.resolve():
        raise HTTPException(status_code=403, detail="Access denied")

    if not file_path.exists():
        raise HTTPException(status_code=404, detail="File not found")

    try:
        file_path.unlink()
        return FileDeleteResponse(status="deleted", filename=filename)
    except Exception as e:
        logger.exception("Error deleting file %s", filename)
        raise HTTPException(status_code=500, detail="Failed to delete file") from e


# Serve Flutter web app (if exists)
if settings.web_build_folder.exists():
    app.mount(
        "/", StaticFiles(directory=settings.web_build_folder, html=True), name="static"
    )


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", "5040"))

    # Bind to 0.0.0.0 in development to be reachable from other processes/containers
    host = os.getenv("HOST", "0.0.0.0")  # noqa: S104

    uvicorn.run(
        "server:app",
        host=host,
        port=port,
        reload=os.getenv("ENVIRONMENT", "production") != "production",
        log_level=settings.log_level.lower(),
    )
