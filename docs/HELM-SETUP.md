# Helm Chart 설정 가이드

## 아키텍처

ArgoCD를 **매니페스트 렌더링 전용**으로 배포한다. GitOps sync/deploy 기능은 사용하지 않는다.

```
argocd CLI → API Server (REST) → repo-server (gRPC) → helm template / kustomize build
                                        ↕
                                      Redis (cache)
```

## values.yaml 설정 상세

### 비활성화된 컴포넌트

| 컴포넌트 | 설정 | 이유 |
|----------|------|------|
| `controller.replicas: 0` | Application Controller | GitOps 동기화 불필요 |
| `dex.enabled: false` | Dex (SSO) | SSO 인증 불필요 |
| `applicationSet.replicas: 0` | ApplicationSet Controller | ApplicationSet CRD 불필요 |
| `notifications.enabled: false` | Notifications | 알림 불필요 |
| `redis-ha.enabled: false` | Redis HA | 단일 인스턴스로 충분 |
| `crds.install: false` | ArgoCD CRDs | 클러스터에 이미 존재하거나 불필요 |
| `configs.rbac.create: false` | RBAC ConfigMap | 기본 admin 계정 사용 |

### 활성화된 컴포넌트

#### repo-server (렌더링 엔진)

```yaml
repoServer:
  replicas: 1
  service:
    port: 8081            # gRPC 포트
  metrics:
    enabled: true
    service:
      port: 8084          # Prometheus 메트릭
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      memory: 4Gi         # 큰 차트 렌더링 시 메모리 필요
  env:
    - name: ARGOCD_EXEC_TIMEOUT
      value: "300s"       # 렌더링 타임아웃
    - name: ARGOCD_GIT_ATTEMPTS_COUNT
      value: "3"          # Git clone 재시도
    - name: ARGOCD_GIT_RETRY_MAX_DURATION
      value: "30s"        # 재시도 간 최대 대기
```

#### server (API 서버)

```yaml
server:
  replicas: 1
  service:
    type: ClusterIP
    port: 80
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      memory: 2Gi
```

`argocd` CLI가 API 서버를 경유하므로 필수. 렌더링 요청 흐름:

```
argocd app manifests <app>
  → GET /api/v1/applications/<app>/manifests
    → gRPC GenerateManifest() → repo-server
```

#### Redis (캐시)

```yaml
redis:
  enabled: true
```

repo-server가 Git 메타데이터와 렌더링 결과를 캐시한다. 비활성화 시 매 요청마다 Git clone이 발생하여 성능 저하.

### configs

```yaml
configs:
  cm:
    timeout.reconciliation: 300s    # reconciliation 타임아웃
    exec.timeout: 300s              # exec 타임아웃
```

## 레포지토리 화이트리스트

별도 프록시 없이 ArgoCD 네이티브 기능 사용:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: rendering
spec:
  sourceRepos:
    - 'https://github.com/my-org/*'        # glob 패턴 지원
    - '!https://github.com/my-org/secret'  # deny 패턴
```

## 테스트 방법

### 자동 테스트

```bash
./scripts/test-deploy.sh
```

상세 내용은 [scripts/test-deploy.sh](../scripts/test-deploy.sh) 참조.

### 수동 테스트

```bash
# 1. 배포
kubectl create namespace argocd-test
helm install test-renderer helm/ --namespace argocd-test --wait --timeout 5m

# 2. Pod 확인
kubectl get pods -n argocd-test

# 3. 포트포워드 + 로그인
kubectl port-forward -n argocd-test svc/test-renderer-argocd-server 8443:443 &
PASS=$(kubectl -n argocd-test get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8443 --username admin --password "$PASS" --insecure --grpc-web

# 4. 테스트 앱 생성 + 렌더링
argocd app create test-helm \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path helm-guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --grpc-web

# REST API로 매니페스트 확인
TOKEN=$(curl -sk https://localhost:8443/api/v1/session \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"admin\",\"password\":\"$PASS\"}" | python3 -c "import sys,json;print(json.load(sys.stdin)['token'])")

curl -sk "https://localhost:8443/api/v1/applications/test-helm/manifests" \
  -H "Authorization: Bearer $TOKEN"

# 5. 정리
pkill -f "port-forward.*argocd-test"
helm uninstall test-renderer -n argocd-test
kubectl delete namespace argocd-test
```
