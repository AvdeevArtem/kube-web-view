FROM python:3.13.3-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    python3-dev \
    cargo \
    openssl-dev \
    git

WORKDIR /app

# Install uv
RUN pip install --no-cache-dir uv

# Copy dependency files
COPY pyproject.toml uv.lock /app/

# Install dependencies
RUN uv pip install --system -r <(uv pip compile --python-version 3.13 pyproject.toml)

# Second stage: minimal runtime image
FROM python:3.13.3-alpine

# Install runtime dependencies
RUN apk add --no-cache \
    libxml2 \
    libxslt \
    openssl \
    # Add tzdata for timezone support
    tzdata \
    # Add CA certificates for HTTPS connections
    ca-certificates && \
    # Clean up cache to reduce image size
    rm -rf /var/cache/apk/*

WORKDIR /app

# Copy Python packages from builder stage
COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY kube_web /app/kube_web

ARG VERSION=dev

# Replace build version in package and
# add build version to static asset links to break browser cache
RUN sed -i "s/^__version__ = .*/__version__ = \"${VERSION}\"/" /app/kube_web/__init__.py && \
    sed -i "s/v=[0-9A-Za-z._-]*/v=${VERSION}/g" /app/kube_web/templates/base.html

# Create a non-root user to run the application
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Create and set proper permissions for directories that need write access
RUN mkdir -p /tmp/kube-web-view && \
    chown -R appuser:appgroup /tmp/kube-web-view

# Switch to non-root user
USER appuser

# Set Python path to include our application
ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    # Set temporary directory to a writable location
    TMPDIR=/tmp/kube-web-view

# Expose the default port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q --spider http://localhost:8080/health || exit 1

# Run the application
ENTRYPOINT ["python", "-m", "kube_web"]
