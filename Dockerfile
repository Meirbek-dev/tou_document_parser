# Use Python 3.13 slim image as base
FROM python:3.13-slim

# Set working directory
WORKDIR /app

# Install system dependencies for Tesseract, Poppler (for pdf2image), and other tools
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    tesseract-ocr-rus \
    tesseract-ocr-eng \
    poppler-utils \
    && rm -rf /var/lib/apt/lists/*

# Copy Python dependencies file
COPY pyproject.toml ./

# Install uv for faster package management (optional, or use pip)
RUN pip install --no-cache-dir uv && \
    uv pip install --system flask flask-cors pdf2image pillow pytesseract werkzeug

# Copy application files
COPY server.py ./
COPY build/web ./build/web

# Create uploads directory
RUN mkdir -p uploads

# Set environment variables for Tesseract
ENV TESSDATA_PREFIX=/usr/share/tesseract-ocr/5/tessdata/

# Expose port
EXPOSE 5040

# Run the application
CMD ["uv", "run", "server.py"]
