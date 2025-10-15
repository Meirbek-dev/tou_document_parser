import os

# Set paths before importing pytesseract
os.environ["TESSDATA_PREFIX"] = r"C:\tools\tesseract\tessdata"

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

pytesseract.pytesseract.tesseract_cmd = r"C:\tools\tesseract\tesseract.exe"
app = Flask(__name__)
CORS(app)
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

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
    return any(
        filename.lower().endswith(ext) for ext in [".pdf", ".jpg", ".jpeg", ".png"]
    )


def optimize_image(img, max_size=2000):
    """Resize image to improve OCR speed while maintaining quality"""
    if max(img.size) > max_size:
        img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
    return img


def extract_text(file_bytes, ext, max_pages=3):
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
    """Process a single file - designed to run in parallel"""
    raw_name, file_bytes = file_data
    ext = os.path.splitext(raw_name)[1].lower()

    if not allowed_file(raw_name):
        return None

    filename = secure_filename(raw_name)

    # Extract text and classify
    text = extract_text(file_bytes, ext)
    print(f"Extracted {len(text)} chars from {filename}")
    category = classify(text)

    new_name = None
    if category != "Unclassified":
        # Generate unique filename
        existing = [
            f
            for f in os.listdir(UPLOAD_FOLDER)
            if f.startswith(f"{name}_{lastname}_{category}")
        ]
        index = len(existing) + 1
        new_name = f"{name}_{lastname}_{category}{index}{ext}"
        path = os.path.join(UPLOAD_FOLDER, new_name)
        with open(path, "wb") as f:
            f.write(file_bytes)

    return {
        "original_name": filename,
        "category": category,
        "new_name": new_name
    }


@app.route("/upload", methods=["POST"])
def upload():
    name = request.form.get("name", "").strip()
    lastname = request.form.get("lastname", "").strip()

    if not name or not lastname:
        return jsonify({"error": "Name and Lastname required"}), 400

    files = request.files.getlist("files")
    if not files:
        return jsonify({"error": "No files provided"}), 400

    # Read all files into memory first (quick operation)
    file_data_list = []
    for file in files:
        if allowed_file(file.filename):
            file_data_list.append((file.filename, file.read()))

    if not file_data_list:
        return jsonify({"error": "No valid files provided"}), 400

    print(f"Processing {len(file_data_list)} files in parallel with {MAX_WORKERS} workers...")

    # Process files in parallel
    results = []
    futures = []

    for file_data in file_data_list:
        future = executor.submit(process_single_file, file_data, name, lastname)
        futures.append(future)

    # Collect results as they complete
    for future in as_completed(futures):
        try:
            result = future.result()
            if result:
                results.append(result)
        except Exception as e:
            print(f"Error processing file: {e}")
            import traceback
            traceback.print_exc()

    print(f"Completed processing {len(results)} files")
    return jsonify(results)


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


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5040, debug=True)
