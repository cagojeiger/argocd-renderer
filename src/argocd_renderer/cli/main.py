"""CLI entrypoint for ArgoCD Renderer."""

import json

import httpx
import typer

app = typer.Typer(
    name="argocd-renderer",
    help="ArgoCD Renderer CLI",
    no_args_is_help=True,
)

whitelist_app = typer.Typer(help="Whitelist management commands")
app.add_typer(whitelist_app, name="whitelist")

DEFAULT_SERVER_URL = "http://localhost:8080"


@app.callback()
def main() -> None:
    """ArgoCD Renderer CLI."""
    pass


@app.command()
def render(
    repo: str = typer.Option(..., "--repo", "-r", help="Git repository URL"),
    path: str = typer.Option(".", "--path", "-p", help="Path within the repository"),
    revision: str = typer.Option("HEAD", "--revision", "-v", help="Git revision to render"),
    server: str = typer.Option(DEFAULT_SERVER_URL, "--server", "-s", help="Server URL"),
    output: str = typer.Option("json", "--output", "-o", help="Output format (json, yaml)"),
) -> None:
    """Render Kubernetes manifests from a Git repository."""
    try:
        with httpx.Client(timeout=30.0) as client:
            response = client.post(
                f"{server}/render",
                json={
                    "repoURL": repo,
                    "path": path,
                    "targetRevision": revision,
                },
            )

            if response.status_code == 403:
                error_data = response.json()
                typer.echo(f"Error: {error_data.get('detail', 'Repository not allowed')}", err=True)
                raise typer.Exit(code=1)

            response.raise_for_status()
            result = response.json()

            if output == "json":
                typer.echo(json.dumps(result, indent=2))
            else:
                typer.echo(f"repoURL: {result['repoURL']}")
                typer.echo(f"path: {result['path']}")
                typer.echo(f"targetRevision: {result['targetRevision']}")
                typer.echo(f"mock: {result['mock']}")
                typer.echo("manifests:")
                for manifest in result.get("manifests", []):
                    typer.echo(f"  - {manifest.get('kind', 'Unknown')}/{manifest.get('metadata', {}).get('name', 'unknown')}")

    except httpx.ConnectError:
        typer.echo(f"Error: Cannot connect to server at {server}", err=True)
        raise typer.Exit(code=1)
    except httpx.HTTPStatusError as e:
        typer.echo(f"Error: HTTP {e.response.status_code}", err=True)
        raise typer.Exit(code=1)


@whitelist_app.command("list")
def whitelist_list(
    server: str = typer.Option(DEFAULT_SERVER_URL, "--server", "-s", help="Server URL"),
) -> None:
    """List current whitelist patterns."""
    try:
        with httpx.Client(timeout=10.0) as client:
            response = client.get(f"{server}/whitelist")
            response.raise_for_status()
            result = response.json()

            typer.echo("Whitelist patterns:")
            for pattern in result.get("patterns", []):
                typer.echo(f"  - {pattern}")

    except httpx.ConnectError:
        typer.echo(f"Error: Cannot connect to server at {server}", err=True)
        raise typer.Exit(code=1)
    except httpx.HTTPStatusError as e:
        typer.echo(f"Error: HTTP {e.response.status_code}", err=True)
        raise typer.Exit(code=1)


if __name__ == "__main__":
    app()
