# syntax=docker/dockerfile:1

FROM python:3.11-slim AS builder

WORKDIR /app

# Install uv for faster dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Copy project files
COPY pyproject.toml README.md ./
COPY src/argocd_renderer/ src/argocd_renderer/

# Create virtual environment and install dependencies
RUN uv venv /app/.venv && \
    . /app/.venv/bin/activate && \
    uv pip install .

# Production stage
FROM python:3.11-slim

WORKDIR /app

# Create non-root user
RUN useradd --create-home --shell /bin/bash appuser

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Set environment variables
ENV PATH="/app/.venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV ARGOCD_RENDERER_HOST=0.0.0.0
ENV ARGOCD_RENDERER_PORT=8080
ENV ARGOCD_RENDERER_WHITELIST_PATH=/etc/argocd-renderer/whitelist.yaml

# Create config directory
RUN mkdir -p /etc/argocd-renderer && \
    chown -R appuser:appuser /etc/argocd-renderer

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8080/healthz').raise_for_status()"

# Run the application
CMD ["python", "-m", "uvicorn", "argocd_renderer.app.main:app", "--host", "0.0.0.0", "--port", "8080"]
