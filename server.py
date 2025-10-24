import os
import sys

# Set paths before importing pytesseract
# Check if running in Docker or Windows
if sys.platform == "win32":
    os.environ["TESSDATA_PREFIX"] = r"C:\tools\tesseract\tessdata"
else:
    # Linux/Docker environment
    os.environ["TESSDATA_PREFIX"] = os.getenv("TESSDATA_PREFIX", "/usr/share/tesseract-ocr/5/tessdata/")

import pytesseract
from PIL import Image
from pdf2image import convert_from_bytes
from flask import Flask, request, jsonify, send_file, send_from_directory
from werkzeug.utils import secure_filename
from flask_cors import CORS
import io
import zipfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from functools import lru_cache
import logging
import tempfile

# Set tesseract command path based on platform
if sys.platform == "win32":
    pytesseract.pytesseract.tesseract_cmd = r"C:\tools\tesseract\tesseract.exe"
else:
    # In Docker/Linux, tesseract is in PATH
    pytesseract.pytesseract.tesseract_cmd = "tesseract"
app = Flask(__name__)
CORS(app)
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Basic logging for production visibility
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
logger = logging.getLogger(__name__)

# Configuration: limits and settings (can be overridden with env vars)
MAX_FILE_SIZE = int(os.getenv("MAX_FILE_SIZE", 100 * 1024 * 1024))  # 50 MB per file
MAX_REQUEST_SIZE = int(os.getenv("MAX_REQUEST_SIZE", 500 * 1024 * 1024))  # 500 MB total

# Thread pool for parallel processing
MAX_WORKERS = min(4, os.cpu_count() or 1)
executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)

CATEGORIES = {
    "Udostoverenie": ["удостоверение", "ID"],
    "ENT": [
        "сертификат",
        "ТЕСТИРОВАНИЯ",
        "ТЕСТІЛЕУ",
        "ТЕСТИРУЕМОГО",
        "Набранные баллы",
    ],
    "Lgota": ["льгота", "инвалид", "многодетная"],
    "Diplom": ["диплом", "аттестат", "бакалавр", "магистр"],
    "Privivka": [
        "прививка",
        "прививочный паспорт",
        "вакцинирование",
        "инфекция",
    ],
    "MedSpravka": [
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

ALLOWED_EXTENSIONS = {"pdf", "jpg", "jpeg", "png"}


def allowed_file(filename):
    if not filename:
        return False
    ext = os.path.splitext(filename)[1].lower()
    return ext in {".pdf", ".jpg", ".jpeg", ".png"}


def optimize_image(img, max_size=2000):
    """Resize image to improve OCR speed while maintaining quality"""
    if max(img.size) > max_size:
        img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
    return img


def extract_text(file_bytes, ext, max_pages=10):
    """
    Extract text with optimizations:
    - Only process first few pages of PDFs
    - Resize images for faster OCR
    - Use faster OCR config
    """
    ocr_config = '--psm 3 --oem 1'  # Faster OCR mode

    if ext == ".pdf":
        # Only convert first few pages for classification
        images = convert_from_bytes(file_bytes, first_page=1, last_page=max_pages)
        texts = []
        for img in images:
            img = optimize_image(img)
            text = pytesseract.image_to_string(img, lang="rus", config=ocr_config)
            texts.append(text)
            # Early exit if we have enough text for classification
            combined = "\n".join(texts)
            if len(combined) > 500:  # Enough text to classify
                break
        return "\n".join(texts)
    else:
        img = Image.open(io.BytesIO(file_bytes))
        img = optimize_image(img)
        return pytesseract.image_to_string(img, lang="rus", config=ocr_config)


@lru_cache(maxsize=128)
def classify(text):
    """Classify text with caching to avoid reprocessing"""
    text_lower = text.lower()
    best_match = "Unclassified"
    max_hits = 0

    for category, keywords in CATEGORIES.items():
        hits = sum(1 for keyword in keywords if keyword.lower() in text_lower)
        if hits > 0:
            print(
                f"Category: {category}, Hits: {hits}, Matched Keywords: {[keyword for keyword in keywords if keyword.lower() in text_lower]}"
            )
        if hits > max_hits:
            max_hits = hits
            best_match = category

    return best_match


def process_single_file(file_data, name, lastname):
    """Process a single file - designed to run in parallel.

    Expects file_data as (original_name, temp_path). Reads the temp file
    contents in a controlled way, classifies and optionally stores the file.
    Always attempts to remove the temporary file.
    """
    raw_name, tmp_path = file_data
    ext = os.path.splitext(raw_name)[1].lower()

    if not allowed_file(raw_name):
        try:
            os.remove(tmp_path)
        except Exception:
            pass
        return None

    filename = secure_filename(raw_name)

    try:
        with open(tmp_path, "rb") as fh:
            file_bytes = fh.read()

        # Extract text and classify
        text = extract_text(file_bytes, ext)
        logger.info("Extracted %d chars from %s", len(text), filename)
        category = classify(text)

        new_name = None
        if category != "Unclassified":
            # sanitize name/lastname for filesystem usage
            def safe_part(s: str) -> str:
                if not s:
                    return "anon"
                safe = "".join(c for c in s if c.isalnum() or c in ('_', '-'))
                return safe or "anon"

            base_name = f"{safe_part(name)}_{safe_part(lastname)}_{category}"

            # Generate unique filename
            index = 1
            while True:
                candidate = f"{base_name}{index}{ext}"
                path = os.path.join(UPLOAD_FOLDER, candidate)
                if not os.path.exists(path):
                    new_name = candidate
                    break
                index += 1

            with open(path, "wb") as f:
                f.write(file_bytes)

        return {"original_name": filename, "category": category, "new_name": new_name}
    finally:
        try:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
        except Exception:
            pass


@app.route("/upload", methods=["POST"])
def upload():
    name = request.form.get("name", "").strip()
    lastname = request.form.get("lastname", "").strip()

    if not name or not lastname:
        return jsonify({"error": "Name and Lastname required"}), 400

    # Basic request size guard
    content_length = request.content_length
    if content_length and content_length > MAX_REQUEST_SIZE:
        return jsonify({"error": "Request too large"}), 413

    files = request.files.getlist("files")
    if not files:
        return jsonify({"error": "No files provided"}), 400

    # Save each uploaded file to a temporary file on disk and validate size
    file_data_list = []  # tuples of (original_name, temp_path)
    try:
        for file_storage in files:
            if not file_storage or not file_storage.filename:
                continue

            original_name = file_storage.filename

            if not allowed_file(original_name):
                logger.warning("Rejected disallowed file type: %s", original_name)
                continue

            # Check MIME type if provided
            content_type = file_storage.mimetype
            if content_type:
                if not (content_type.startswith("image/") or content_type == "application/pdf"):
                    logger.warning("Rejected unexpected content-type %s for %s", content_type, original_name)
                    continue

            # Stream to temporary file and enforce per-file size
            tmp_fd, tmp_path = tempfile.mkstemp(prefix="upload_", suffix=os.path.splitext(original_name)[1])
            os.close(tmp_fd)
            total = 0
            try:
                with open(tmp_path, "wb") as out_f:
                    chunk = file_storage.stream.read(8192)
                    while chunk:
                        total += len(chunk)
                        if total > MAX_FILE_SIZE:
                            raise ValueError("File too large")
                        out_f.write(chunk)
                        chunk = file_storage.stream.read(8192)
            except Exception as e:
                try:
                    os.remove(tmp_path)
                except Exception:
                    pass
                logger.exception("Error saving uploaded file %s: %s", original_name, e)
                return jsonify({"error": "Failed to save uploaded file"}), 400

            file_data_list.append((original_name, tmp_path))

        if not file_data_list:
            return jsonify({"error": "No valid files uploaded"}), 400

        logger.info("Processing %d files in parallel with %d workers", len(file_data_list), MAX_WORKERS)

        # Process files in parallel
        results = []
        futures = [executor.submit(process_single_file, file_data, name, lastname) for file_data in file_data_list]

        # Collect results as they complete
        for future in as_completed(futures):
            try:
                res = future.result()
                if res:
                    results.append(res)
            except Exception as e:
                logger.exception("Error processing file: %s", e)

        logger.info("Completed processing %d files", len(results))
        return jsonify(results)
    finally:
        # Cleanup any temporary files that might remain (defensive)
        for _, tmp_path in file_data_list:
            try:
                if os.path.exists(tmp_path):
                    os.remove(tmp_path)
            except Exception:
                pass


@app.route("/files/<filename>")
def download_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename, as_attachment=True)


@app.route("/download_zip")
def download_zip():
    name = request.args.get("name", "").strip()
    lastname = request.args.get("lastname", "").strip()
    prefix = f"{name}_{lastname}_"

    zip_stream = io.BytesIO()
    with zipfile.ZipFile(zip_stream, "w", zipfile.ZIP_DEFLATED) as archive:
        for fname in os.listdir(UPLOAD_FOLDER):
            if fname.startswith(prefix):
                path = os.path.join(UPLOAD_FOLDER, fname)
                archive.write(path, arcname=fname)

    zip_stream.seek(0)
    return send_file(
        zip_stream,
        mimetype="application/zip",
        as_attachment=True,
        download_name="documents.zip",
    )


@app.route("/delete_file", methods=["DELETE"])
def delete_file():
    filename = request.args.get("filename", "")
    path = os.path.join(UPLOAD_FOLDER, filename)
    if os.path.exists(path):
        os.remove(path)
        return jsonify({"status": "deleted"})
    return jsonify({"error": "File not found"}), 404


# Serve Flutter web app
@app.route("/")
def index():
    return send_from_directory("build/web", "index.html")


@app.route("/<path:path>")
def serve_static(path):
    # Serve files from build/web (compiled Flutter web app)
    build_web_path = os.path.join("build/web", path)
    if os.path.exists(build_web_path):
        return send_from_directory("build/web", path)

    # If not found, serve index.html for client-side routing (SPA behavior)
    return send_from_directory("build/web", "index.html")


if __name__ == "__main__":
    # Get port from environment variable or default to 5040
    port = int(os.getenv("PORT", 5040))
    # Disable debug in production
    debug = os.getenv("FLASK_ENV", "production") != "production"
    app.run(host="0.0.0.0", port=port, debug=debug)
