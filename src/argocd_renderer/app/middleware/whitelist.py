"""Whitelist validation middleware for ArgoCD Renderer."""

import json
from fnmatch import fnmatch

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse


class WhitelistMiddleware(BaseHTTPMiddleware):
    """Middleware to validate repoURL against whitelist patterns."""

    def __init__(self, app, whitelist_patterns: list[str]):
        super().__init__(app)
        self.whitelist_patterns = whitelist_patterns

    async def dispatch(self, request: Request, call_next):
        """Process request and validate repoURL if present."""
        # Only validate POST /render requests
        if request.method == "POST" and request.url.path == "/render":
            try:
                body = await request.body()
                if body:
                    data = json.loads(body)
                    repo_url = data.get("repoURL")

                    if repo_url and not self._is_allowed(repo_url):
                        return JSONResponse(
                            status_code=403,
                            content={
                                "detail": f"Repository URL not allowed: {repo_url}",
                                "allowed_patterns": self.whitelist_patterns,
                            },
                        )
            except json.JSONDecodeError:
                pass  # Let the endpoint handle invalid JSON

        response = await call_next(request)
        return response

    def _is_allowed(self, repo_url: str) -> bool:
        """Check if repo_url matches any whitelist pattern."""
        for pattern in self.whitelist_patterns:
            if fnmatch(repo_url, pattern):
                return True
        return False
