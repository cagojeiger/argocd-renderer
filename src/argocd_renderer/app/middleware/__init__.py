"""Middleware modules for ArgoCD Renderer."""

from argocd_renderer.app.middleware.whitelist import WhitelistMiddleware

__all__ = ["WhitelistMiddleware"]
