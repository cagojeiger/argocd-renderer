"""Tests for health endpoint."""

import pytest
from fastapi.testclient import TestClient

from argocd_renderer.app.main import app


@pytest.fixture
def client():
    """Create test client."""
    return TestClient(app)


class TestHealthEndpoint:
    """Tests for /healthz endpoint."""

    def test_health_check(self, client):
        """Test health check returns ok status."""
        response = client.get("/healthz")
        assert response.status_code == 200
        assert response.json() == {"status": "ok"}
