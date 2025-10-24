# Multi-stage build for optimized image size
FROM python:3.13-slim as builder

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

# Install Python packages
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    flask==3.1.2 \
    flask-cors==6.0.1 \
    pdf2image==1.17.0 \
    pillow==11.3.0 \
    pytesseract==0.3.13 \
    werkzeug==3.1.3 \
    gunicorn==23.0.0

# Production stage
FROM python:3.13-slim

WORKDIR /app

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    tesseract-ocr-rus \
    tesseract-ocr-eng \
    poppler-utils \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy Python packages from builder
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application files
COPY server.py ./
COPY web ./web
COPY build ./build

# Create uploads directory with proper permissions
RUN mkdir -p uploads && \
    chmod 755 uploads

# Create non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Set environment variables for Tesseract
ENV TESSDATA_PREFIX=/usr/share/tesseract-ocr/5/tessdata/
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=production

# Expose port
EXPOSE 5040

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5040/')" || exit 1

# Run the application with gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:5040", "--workers", "4", "--threads", "2", "--timeout", "120", "server:app"]
