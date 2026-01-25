"""Configuration management for ArgoCD Renderer."""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(env_prefix="ARGOCD_RENDERER_")

    whitelist_patterns: list[str] = ["https://github.com/*"]
    mock_mode: bool = True
    upstream_url: str = ""


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
