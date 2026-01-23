# ArgoCD Renderer 로드맵

## 개요

ArgoCD 기반 매니페스트 렌더링 서비스로, 다음 컴포넌트로 구성됩니다:

1. **Helm 차트**: ArgoCD repo-server 배포
2. **Proxy (app)**: L7 프록시, 화이트리스트 기반 repo URL 검증
3. **CLI**: 렌더링 요청 및 관리 도구

## 아키텍처

```
                    ┌─────────────────────────────────────────────────┐
                    │              Kubernetes Cluster                  │
                    │                                                  │
┌─────────┐        │  ┌─────────────┐      ┌───────────────────────┐ │
│ Client  │───────▶│  │   Proxy     │─────▶│    ArgoCD Server      │ │
│ (CLI)   │        │  │ (whitelist) │      │    + repo-server      │ │
└─────────┘        │  └─────────────┘      └───────────────────────┘ │
                    │         │                                       │
                    │         ▼                                       │
                    │  ┌─────────────┐                                │
                    │  │ ConfigMap   │                                │
                    │  │ (whitelist) │                                │
                    │  └─────────────┘                                │
                    └─────────────────────────────────────────────────┘
```

## 프로젝트 구조

```
argocd-renderer/
├── helm/                              # Helm 차트
│   ├── whitelist.yaml                 # 허용 repo 목록
│   ├── values.yaml
│   └── templates/
│       └── proxy-configmap.yaml
│
├── api/                               # OpenAPI 명세
│   └── openapi.yaml
│
├── src/                               # 소스코드
│   ├── argocd_renderer/
│   │   ├── app/                       # 서버 (프록시)
│   │   │   ├── main.py
│   │   │   ├── config.py
│   │   │   ├── middleware/
│   │   │   │   └── whitelist.py
│   │   │   └── proxy/
│   │   │       └── handler.py
│   │   │
│   │   └── cli/                       # CLI
│   │       └── main.py
│   │
│   ├── Dockerfile
│   └── pyproject.toml
│
├── tests/
│   ├── test_whitelist.py
│   └── test_cli.py
│
└── docs/
    └── ROADMAP.md
```

---

## 마일스톤

### Phase 1: 기본 인프라 (완료)
- [x] Helm 차트 생성 (argo-cd 의존성)
- [x] GitHub Pages Helm repo 설정
- [x] CI/CD 파이프라인 구축
- [x] Ingress/Gateway/VirtualService 템플릿

### Phase 2: Proxy 서버 구현
- [ ] 프로젝트 초기화 (pyproject.toml, 디렉토리 구조)
- [ ] OpenAPI 명세 작성
- [ ] 화이트리스트 검증 미들웨어
- [ ] Upstream 프록시 핸들러
- [ ] FastAPI 앱 구성
- [ ] Dockerfile 작성

### Phase 3: CLI 구현
- [ ] CLI 엔트리포인트
- [ ] 렌더링 명령어
- [ ] 화이트리스트 관리 명령어

### Phase 4: Helm 차트 통합
- [ ] whitelist.yaml 설정
- [ ] Proxy ConfigMap 템플릿
- [ ] Proxy sidecar 설정
- [ ] NetworkPolicy (egress 제한)

### Phase 5: 테스트 및 문서화
- [ ] 단위 테스트
- [ ] 통합 테스트
- [ ] API 문서
- [ ] 사용자 가이드

---

## 기술 스택

| 카테고리 | 기술 |
|---------|------|
| 언어 | Python 3.13+ |
| 웹 프레임워크 | FastAPI |
| HTTP 클라이언트 | httpx |
| CLI | Typer |
| 설정 관리 | pydantic-settings |
| 패키지 관리 | uv |
| 컨테이너 | Docker |
| 배포 | Helm, Kubernetes |

---

## 보안 고려사항

### 오픈 서비스 보안 전략 (Open A 방식)
- 인증 없이 접근 가능
- **화이트리스트 기반 repo 검증** (핵심)

### 보안 레이어

| 레이어 | 구현 |
|-------|------|
| L7 Proxy | repoURL 화이트리스트 검증 |
| NetworkPolicy | Egress 제한 (github.com, gitlab.com만 허용) |
| Pod Security | runAsNonRoot, readOnlyRootFilesystem |
| Rate Limiting | Ingress/Gateway annotation |

### 화이트리스트 예시

```yaml
# helm/whitelist.yaml
allowedRepos:
  - pattern: "https://github.com/argoproj/*"
  - pattern: "https://github.com/my-org/*"
  - pattern: "https://gitlab.com/my-group/*"
```

---

## CLI 사용 예시 (예정)

```bash
# 렌더링 요청
argocd-renderer render \
  --repo https://github.com/org/chart \
  --path charts/app \
  --target-revision main

# 화이트리스트 확인
argocd-renderer whitelist list
argocd-renderer whitelist check https://github.com/org/chart
```

---

## 의존성

```toml
[project]
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn>=0.32.0",
    "httpx>=0.28.0",
    "pydantic-settings>=2.0.0",
    "pyyaml>=6.0.0",
    "typer>=0.12.0",
]
```
