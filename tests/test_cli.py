"""Tests for CLI commands."""

from typer.testing import CliRunner

from argocd_renderer.cli.main import app

runner = CliRunner()


class TestCLIHelp:
    """Tests for CLI help commands."""

    def test_main_help(self):
        """Test main help command."""
        result = runner.invoke(app, ["--help"])
        assert result.exit_code == 0
        assert "ArgoCD Renderer CLI" in result.stdout
