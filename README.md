# argocd-renderer

ArgoCD 기반 매니페스트 렌더링 전용 서비스. 배포/동기화 기능 없이 repo-server만 사용하여 Kubernetes 매니페스트를 렌더링합니다.

## 설치

### Helm Repository 추가

```bash
helm repo add argocd-renderer https://cagojeiger.github.io/argocd-renderer
helm repo update
```

### 차트 설치

```bash
helm install argocd-renderer argocd-renderer/argocd-renderer -n argocd --create-namespace
```

### 특정 버전 설치

```bash
# 버전 확인
helm search repo argocd-renderer --versions

# 특정 버전 설치
helm install argocd-renderer argocd-renderer/argocd-renderer --version 9.3.4 -n argocd --create-namespace
```

### Values 커스터마이징

```bash
# 기본 values 확인
helm show values argocd-renderer/argocd-renderer

# 커스텀 values로 설치
helm install argocd-renderer argocd-renderer/argocd-renderer -f my-values.yaml -n argocd --create-namespace
```

## 아키텍처

```
┌─────────────────┐
│   ArgoCD UI     │
│   (Server)      │
│ Port: 80/TCP    │
└────────┬────────┘
         │
┌────────▼────────┐
│  Repo-Server    │
│ (Renderer)      │
│ Port: 8081 gRPC │
└─────────────────┘

✓ No Controller (동기화/배포 없음)
✓ Rendering Only
```

## 활성화된 컴포넌트

| 컴포넌트 | 역할 | 포트 |
|----------|------|------|
| repo-server | 매니페스트 렌더링 | 8081 (gRPC) |
| server | Web UI/API | 80 |

## 비활성화된 컴포넌트

- Controller (동기화/배포)
- ApplicationSet Controller
- Dex (인증)
- Notifications
- Redis

## License

MIT
