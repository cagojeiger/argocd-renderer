"""FastAPI application entrypoint for ArgoCD Renderer."""

from fastapi import FastAPI
from pydantic import BaseModel, Field

from argocd_renderer.app.config import get_settings
from argocd_renderer.app.middleware.whitelist import WhitelistMiddleware

settings = get_settings()

app = FastAPI(
    title="ArgoCD Renderer",
    description="ArgoCD manifest renderer service",
    version="0.1.0",
)

# Add whitelist middleware
app.add_middleware(WhitelistMiddleware, whitelist_patterns=settings.whitelist_patterns)


class RenderRequest(BaseModel):
    """Request model for render endpoint."""

    repoURL: str = Field(..., description="Git repository URL")
    path: str = Field(default=".", description="Path within the repository")
    targetRevision: str = Field(default="HEAD", description="Git revision to render")


class RenderResponse(BaseModel):
    """Response model for render endpoint."""

    repoURL: str
    path: str
    targetRevision: str
    manifests: list[dict]
    mock: bool


class WhitelistResponse(BaseModel):
    """Response model for whitelist endpoint."""

    patterns: list[str]


@app.get("/healthz")
async def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "ok"}


@app.post("/render", response_model=RenderResponse)
async def render(request: RenderRequest) -> RenderResponse:
    """
    Render Kubernetes manifests from a Git repository.

    In mock mode, returns an echo response with the request parameters.
    """
    if settings.mock_mode:
        return RenderResponse(
            repoURL=request.repoURL,
            path=request.path,
            targetRevision=request.targetRevision,
            manifests=[
                {
                    "apiVersion": "v1",
                    "kind": "ConfigMap",
                    "metadata": {"name": "mock-manifest"},
                    "data": {
                        "repoURL": request.repoURL,
                        "path": request.path,
                        "targetRevision": request.targetRevision,
                    },
                }
            ],
            mock=True,
        )

    # Production mode - to be implemented
    return RenderResponse(
        repoURL=request.repoURL,
        path=request.path,
        targetRevision=request.targetRevision,
        manifests=[],
        mock=False,
    )


@app.get("/whitelist", response_model=WhitelistResponse)
async def get_whitelist() -> WhitelistResponse:
    """Get current whitelist patterns."""
    return WhitelistResponse(patterns=settings.whitelist_patterns)
