## Multi-stage Dockerfile optimized for size and security
FROM python:3.13.9-slim AS builder

ENV PYTHONUNBUFFERED=1
WORKDIR /app

# Install build-time dependencies (minimal)
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential python3-dev libpoppler-cpp-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Create a virtualenv and install runtime Python packages into it
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy pyproject and install pinned dependencies into the venv
COPY pyproject.toml ./
RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
        flask==3.1.2 \
        flask-cors==6.0.1 \
        pdf2image==1.17.0 \
        pillow==12.0.0 \
        pytesseract==0.3.13 \
        werkzeug==3.1.3 \
        gunicorn==23.0.0

## Final stage: smaller runtime image
FROM python:3.13.9-slim

ENV PYTHONUNBUFFERED=1
WORKDIR /app

# Install runtime OS packages required by tesseract and pdf conversion
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        tesseract-ocr \
        tesseract-ocr-rus \
        tesseract-ocr-eng \
        poppler-utils \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user early and make uploads directory
RUN useradd -m -u 1000 appuser && mkdir -p /app/uploads && chown -R appuser:appuser /app
USER appuser

# Copy the virtualenv from builder
COPY --from=builder --chown=appuser:appuser /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy only the necessary application files
COPY --chown=appuser:appuser server.py ./
COPY --chown=appuser:appuser build ./build

# Ensure uploads dir exists
RUN mkdir -p uploads && chmod 755 uploads

# Environment variables
ENV TESSDATA_PREFIX=/usr/share/tesseract-ocr/5/tessdata/
ENV FLASK_ENV=production

# Expose port and healthcheck
EXPOSE 5040
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD python -c "import urllib.request,sys; r=urllib.request.urlopen('http://127.0.0.1:5040/healthz', timeout=3); sys.exit(0 if r.getcode()==200 else 1)"

# Run with gunicorn (non-root user)
CMD ["gunicorn", "--bind", "0.0.0.0:5040", "--workers", "2", "--threads", "2", "--timeout", "120", "server:app"]

