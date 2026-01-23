"""FastAPI application entrypoint for ArgoCD Renderer."""

from fastapi import FastAPI

app = FastAPI(
    title="ArgoCD Renderer",
    description="ArgoCD manifest renderer service",
    version="0.1.0",
)


@app.get("/healthz")
async def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "ok"}
