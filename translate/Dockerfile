# Simple single-stage build for AMD64
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoremove -y

# Copy requirements first for better caching
COPY requirements-optimized.txt requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge

# Copy application code
COPY . .

# Accept build arguments for model caching and Artifactory
ARG HF_HUB_ETAG_TIMEOUT
ARG HF_HUB_DOWNLOAD_TIMEOUT
ARG HF_ENDPOINT
ARG HF_TOKEN

# Set environment variables for model caching and Artifactory
ENV TRANSFORMERS_CACHE="/app/models"
ENV HF_HOME="/app/models"
ENV HF_HUB_ETAG_TIMEOUT=${HF_HUB_ETAG_TIMEOUT}
ENV HF_HUB_DOWNLOAD_TIMEOUT=${HF_HUB_DOWNLOAD_TIMEOUT}
ENV HF_ENDPOINT=${HF_ENDPOINT}
ENV HF_TOKEN=${HF_TOKEN}

# Create model cache directory
RUN mkdir -p /app/models

# Create a non-root user
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
