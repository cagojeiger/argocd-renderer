"""CLI entrypoint for ArgoCD Renderer."""

import typer

app = typer.Typer(
    name="argocd-renderer",
    help="ArgoCD Renderer CLI",
    no_args_is_help=True,
)


@app.callback()
def main() -> None:
    """ArgoCD Renderer CLI."""
    pass


if __name__ == "__main__":
    app()
