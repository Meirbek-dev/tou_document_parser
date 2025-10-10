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

pytesseract.pytesseract.tesseract_cmd = r"C:\tools\tesseract\tesseract.exe"
app = Flask(__name__)
CORS(app)
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

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


def extract_text(file_bytes, ext):
    if ext == ".pdf":
        images = convert_from_bytes(file_bytes)
        return "\n".join(pytesseract.image_to_string(img, lang="rus") for img in images)
    else:
        img = Image.open(io.BytesIO(file_bytes))
        return pytesseract.image_to_string(img, lang="rus")


def classify(text):
    text = text.lower()
    best_match = "Unclassified"
    max_hits = 0

    for category, keywords in CATEGORIES.items():
        hits = sum(1 for keyword in keywords if keyword.lower() in text)
        print(
            f"Category: {category}, Hits: {hits}, Hitted Keywords: {[keyword for keyword in keywords if keyword.lower() in text]}"
        )
        if hits > max_hits:
            max_hits = hits
            best_match = category

    return best_match


@app.route("/upload", methods=["POST"])
def upload():
    name = request.form.get("name", "").strip()
    lastname = request.form.get("lastname", "").strip()

    if not name or not lastname:
        return jsonify({"error": "Name and Lastname required"}), 400

    files = request.files.getlist("files")
    if not files:
        return jsonify({"error": "No files provided"}), 400

    category_counts = {key: 0 for key in CATEGORIES}
    results = []

    for file in files:
        raw_name = file.filename
        ext = os.path.splitext(raw_name)[1].lower()

        if not allowed_file(raw_name):
            continue

        filename = secure_filename(raw_name)

        file_bytes = file.read()
        text = extract_text(file_bytes, ext)
        print(text[:3000])
        category = classify(text)

        if category != "Unclassified":
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
        else:
            new_name = None

        results.append(
            {"original_name": filename, "category": category, "new_name": new_name}
        )

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
