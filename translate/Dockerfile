# Multi-stage build for optimization
FROM python:3.11-slim as builder

# Set working directory
WORKDIR /app

# Install system dependencies for building
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements-optimized.txt requirements.txt

# Install Python dependencies in a virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip cache purge

# Pre-download and cache the translation model
RUN python -c "import os; os.makedirs('/app/models', exist_ok=True); print('Model cache directory created')" || true

# Production stage
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoremove -y

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy cached models
COPY --from=builder /app/models /app/models

# Copy application code
COPY . .

# Accept build arguments for Artifactory configuration
ARG HF_HUB_ETAG_TIMEOUT=86400
ARG HF_HUB_DOWNLOAD_TIMEOUT=86400
ARG HF_ENDPOINT=https://evidencetrial.jfrog.io/artifactory/api/huggingfaceml/dev-huggingfaceml-remote
ARG HF_TOKEN=cmVmdGtuOjAxOjE3ODY5NjY4NTU6VnMwakUzdU80Z2RMeE9pOGo3WDUzTkZvT1VF

# Set environment variables for model caching and Artifactory
ENV TRANSFORMERS_CACHE="/app/models"
ENV HF_HOME="/app/models"
ENV HF_HUB_ETAG_TIMEOUT=${HF_HUB_ETAG_TIMEOUT}
ENV HF_HUB_DOWNLOAD_TIMEOUT=${HF_HUB_DOWNLOAD_TIMEOUT}
ENV HF_ENDPOINT=${HF_ENDPOINT}
ENV HF_TOKEN=${HF_TOKEN}

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
