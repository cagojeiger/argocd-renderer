# argocd-renderer

ArgoCD rendering-only Helm chart. Deploys a minimal ArgoCD setup with only the components needed for manifest rendering (Helm, Kustomize, etc.).

## Components

| Component | Status | Purpose |
|-----------|--------|---------|
| repo-server | Enabled (1 replica) | Manifest rendering engine |
| server | Enabled (1 replica) | API for `argocd` CLI access |
| redis | Enabled | Caching |
| controller | Disabled (0 replicas) | Not needed (no GitOps sync) |
| dex | Disabled | Not needed (no SSO) |
| applicationSet | Disabled (0 replicas) | Not needed |
| notifications | Disabled | Not needed |

## Usage

```bash
helm repo add argocd-renderer https://cagojeiger.github.io/argocd-renderer
helm install argocd-renderer argocd-renderer/argocd-renderer --namespace argocd --create-namespace
```

## License

Apache-2.0
