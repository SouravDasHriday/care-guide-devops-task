# ==============================================================================
# Multi-stage Dockerfile for Flask Web Application
# Adheres to Docker Best Practices:
# 1. Multi-stage build to isolate build dependencies
# 2. Minimal base image (python:3.11-slim)
# 3. Unprivileged non-root user execution (appuser:appgroup)
# 4. Built-in HEALTHCHECK instruction
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Builder stage to install Python dependencies into /install
# ------------------------------------------------------------------------------
FROM python:3.11-slim AS builder

WORKDIR /build

# Set environment flags to prevent bytecode compilation during build
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Copy dependency specifications first to leverage Docker layer caching
COPY requirements.txt .

# Install dependencies into a separate target directory
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ------------------------------------------------------------------------------
# Stage 2: Final lightweight runtime stage
# ------------------------------------------------------------------------------
FROM python:3.11-slim AS runner

# Metadata labels
LABEL maintainer="DevOps Candidate" \
      description="Care Guide DevOps Screening Task Web Application" \
      version="1.0.0"

# Standard production Python runtime environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/install/bin:$PATH" \
    PYTHONPATH="/install/lib/python3.11/site-packages:$PYTHONPATH" \
    PORT=8080

# Install curl for health checking, clean apt cache immediately to keep image slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Create unprivileged system group and user
RUN groupadd -g 1001 appgroup \
    && useradd -u 1001 -g appgroup -s /sbin/nologin -d /app appuser

WORKDIR /app

# Copy installed packages from builder stage
COPY --from=builder /install /install

# Copy application source code and set ownership to non-root user
COPY --chown=appuser:appgroup ./app /app/app

# Switch to non-root user
USER appuser

# Expose target application port
EXPOSE 8080

# Container healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Production command using Gunicorn WSGI server
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "2", "--access-logfile", "-", "--error-logfile", "-", "app.main:app"]
