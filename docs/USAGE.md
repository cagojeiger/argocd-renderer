# 사용 가이드

## 렌더링 흐름

```
Create Application → Get Manifests → Delete Application
```

3단계가 전부다. Application CRD를 임시로 만들고, 렌더링 결과를 가져오고, 삭제한다.

> **주의**: 삭제 시 반드시 `cascade=false`를 사용해야 한다. Controller가 꺼져있어 finalizer 처리가 안 되기 때문.

## CLI 방식

```bash
# 1. 생성
argocd app create my-render \
  --repo https://github.com/my-org/my-repo.git \
  --path charts/my-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --grpc-web

# 2. 렌더링 결과 조회
argocd app manifests my-render --grpc-web

# 3. 삭제 (cascade=false 필수)
argocd app delete my-render --yes --cascade=false --grpc-web
```

## REST API 방식

```bash
TOKEN="<your-token>"
BASE="https://argocd-server:443"

# 1. 생성
curl -sk -X POST "$BASE/api/v1/applications" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "metadata": {"name": "my-render"},
    "spec": {
      "source": {
        "repoURL": "https://github.com/my-org/my-repo.git",
        "path": "charts/my-app",
        "targetRevision": "HEAD"
      },
      "destination": {
        "server": "https://kubernetes.default.svc",
        "namespace": "default"
      },
      "project": "default"
    }
  }'

# 2. 렌더링 결과 조회
curl -sk "$BASE/api/v1/applications/my-render/manifests" \
  -H "Authorization: Bearer $TOKEN"

# 3. 삭제 (cascade=false 필수)
curl -sk -X DELETE "$BASE/api/v1/applications/my-render?cascade=false" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

## Helm values 오버라이드

렌더링 시 values를 오버라이드하려면 source에 `helm` 섹션을 추가한다:

```bash
argocd app create my-render \
  --repo https://github.com/my-org/my-repo.git \
  --path charts/my-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --helm-set image.tag=v1.2.3 \
  --helm-set replicaCount=3 \
  --values values-prod.yaml \
  --grpc-web
```

REST API 동등:

```json
{
  "spec": {
    "source": {
      "repoURL": "https://github.com/my-org/my-repo.git",
      "path": "charts/my-app",
      "targetRevision": "HEAD",
      "helm": {
        "parameters": [
          {"name": "image.tag", "value": "v1.2.3"},
          {"name": "replicaCount", "value": "3"}
        ],
        "valueFiles": ["values-prod.yaml"]
      }
    }
  }
}
```

## 동시 사용

여러 사용자가 동시에 렌더링할 수 있다. 규칙 하나:

**Application 이름을 고유하게 만들어라.**

```bash
NAME="render-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -d- -f1)"
argocd app create "$NAME" --repo ... --grpc-web
argocd app manifests "$NAME" --grpc-web
argocd app delete "$NAME" --yes --cascade=false --grpc-web
```

| 시나리오 | 결과 |
|----------|------|
| 서로 다른 이름 | 충돌 없음 |
| 같은 이름 + 같은 spec | 멱등 (idempotent) |
| 같은 이름 + 다른 spec | 거부됨 (명확한 에러) |

## 토큰 발급

### renderer 서비스 계정 토큰 (권장)

```bash
argocd account generate-token --account renderer
```

`renderer` 계정은 Application create/get/delete만 가능. sync 권한 없음.

### admin 세션 토큰

```bash
PASS=$(kubectl -n <namespace> get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

TOKEN=$(curl -sk https://<argocd-server>/api/v1/session \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"admin\",\"password\":\"$PASS\"}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['token'])")
```

## 검증 결과

실제 클러스터 테스트 결과:

| 항목 | 결과 |
|------|------|
| 기본 렌더링 (create → manifests → delete) | ✅ |
| 리소스 정리 (삭제 후 잔여 리소스 0) | ✅ |
| 동시 5건 병렬 처리 | ✅ |
| 이름 충돌 시 안전 거부 | ✅ |
