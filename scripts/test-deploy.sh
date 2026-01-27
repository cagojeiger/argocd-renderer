#!/usr/bin/env bash
#
# ArgoCD Renderer Helm 차트 배포 테스트
#
# 사용법:
#   ./scripts/test-deploy.sh              # 기본 (argocd-test 네임스페이스)
#   ./scripts/test-deploy.sh my-namespace # 커스텀 네임스페이스
#
# 전제 조건:
#   - kubectl, helm, curl, python3 설치
#   - 유효한 kubeconfig 컨텍스트
#
set -euo pipefail

NAMESPACE="${1:-argocd-test}"
RELEASE="test-renderer"
CHART_DIR="$(cd "$(dirname "$0")/.." && pwd)/helm"
TIMEOUT="5m"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${YELLOW}➡️  $1${NC}"; }

cleanup() {
	info "정리 중..."
	pkill -f "port-forward.*${NAMESPACE}" 2>/dev/null || true
	helm uninstall "$RELEASE" -n "$NAMESPACE" --wait 2>/dev/null || true
	kubectl delete namespace "$NAMESPACE" --wait=true 2>/dev/null || true
	pass "정리 완료"
}

# 항상 정리 (성공/실패/중단 모두)
trap cleanup EXIT

ERRORS=0

# ─── 1. helm lint ───
info "helm lint"
if helm lint "$CHART_DIR" >/dev/null 2>&1; then
	pass "helm lint 통과"
else
	fail "helm lint 실패"
	((ERRORS++))
fi

# ─── 2. helm template ───
info "helm template 검증"
TEMPLATE_OUT=$(helm template "$RELEASE" "$CHART_DIR" --namespace "$NAMESPACE" 2>&1)
if [ $? -eq 0 ]; then
	pass "helm template 렌더링 성공"
else
	fail "helm template 실패"
	echo "$TEMPLATE_OUT"
	((ERRORS++))
fi

# ─── 3. 배포 ───
info "배포: namespace=$NAMESPACE release=$RELEASE"
kubectl create namespace "$NAMESPACE" 2>/dev/null || true
helm install "$RELEASE" "$CHART_DIR" \
	--namespace "$NAMESPACE" \
	--wait --timeout "$TIMEOUT" \
	>/dev/null 2>&1
pass "helm install 성공"

# ─── 4. Pod 상태 확인 ───
info "Pod 상태 확인"
EXPECTED_PODS=("repo-server" "server" "redis")
ALL_RUNNING=true

for comp in "${EXPECTED_PODS[@]}"; do
	STATUS=$(kubectl get pods -n "$NAMESPACE" \
		-l "app.kubernetes.io/component=$comp" \
		-o jsonpath='{.items[0].status.phase}' 2>/dev/null)
	if [ "$STATUS" = "Running" ]; then
		pass "$comp: Running"
	else
		fail "$comp: $STATUS (expected Running)"
		ALL_RUNNING=false
		((ERRORS++))
	fi
done

# controller, applicationSet은 0 replica여야 함
for comp in "application-controller" "applicationset-controller"; do
	COUNT=$(kubectl get pods -n "$NAMESPACE" \
		-l "app.kubernetes.io/component=$comp" \
		--no-headers 2>/dev/null | grep -c Running || echo "0")
	if [ "$COUNT" = "0" ]; then
		pass "$comp: 0 replicas (정상)"
	else
		fail "$comp: $COUNT running (expected 0)"
		((ERRORS++))
	fi
done

# ─── 5. 매니페스트 렌더링 테스트 ───
if [ "$ALL_RUNNING" = true ]; then
	info "매니페스트 렌더링 테스트"

	# 포트포워드 시작
	kubectl port-forward -n "$NAMESPACE" \
		"svc/${RELEASE}-argocd-server" 18443:443 >/dev/null 2>&1 &
	sleep 3

	# admin 비밀번호 가져오기
	PASS=$(kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" | base64 -d)

	# JWT 토큰 발급
	TOKEN=$(curl -sk https://localhost:18443/api/v1/session \
		-H "Content-Type: application/json" \
		-d "{\"username\":\"admin\",\"password\":\"$PASS\"}" |
		python3 -c "import sys,json;print(json.load(sys.stdin).get('token',''))" 2>/dev/null)

	if [ -z "$TOKEN" ]; then
		fail "ArgoCD 로그인 실패"
		((ERRORS++))
	else
		pass "ArgoCD 로그인 성공"

		# 테스트 앱 생성
		CREATE_RESP=$(curl -sk "https://localhost:18443/api/v1/applications" \
			-H "Authorization: Bearer $TOKEN" \
			-H "Content-Type: application/json" \
			-d '{
                "metadata": {"name": "test-helm"},
                "spec": {
                    "project": "default",
                    "source": {
                        "repoURL": "https://github.com/argoproj/argocd-example-apps.git",
                        "path": "helm-guestbook",
                        "targetRevision": "HEAD"
                    },
                    "destination": {
                        "server": "https://kubernetes.default.svc",
                        "namespace": "default"
                    }
                }
            }' 2>/dev/null)

		APP_NAME=$(echo "$CREATE_RESP" | python3 -c "import sys,json;print(json.load(sys.stdin).get('metadata',{}).get('name',''))" 2>/dev/null)

		if [ "$APP_NAME" = "test-helm" ]; then
			pass "테스트 앱 생성 성공"

			# 매니페스트 렌더링
			MANIFESTS=$(curl -sk "https://localhost:18443/api/v1/applications/test-helm/manifests" \
				-H "Authorization: Bearer $TOKEN" 2>/dev/null)

			MANIFEST_COUNT=$(echo "$MANIFESTS" | python3 -c "import sys,json;print(len(json.load(sys.stdin).get('manifests',[])))" 2>/dev/null)

			if [ "$MANIFEST_COUNT" -gt 0 ] 2>/dev/null; then
				pass "매니페스트 렌더링 성공: ${MANIFEST_COUNT}개 리소스"
			else
				fail "매니페스트 렌더링 실패: 0개 리소스"
				((ERRORS++))
			fi
		else
			fail "테스트 앱 생성 실패"
			((ERRORS++))
		fi
	fi

	pkill -f "port-forward.*${NAMESPACE}" 2>/dev/null || true
else
	info "Pod 미기동으로 렌더링 테스트 스킵"
	((ERRORS++))
fi

# ─── 결과 ───
echo ""
echo "════════════════════════════════════════"
if [ "$ERRORS" -eq 0 ]; then
	pass "모든 테스트 통과"
else
	fail "${ERRORS}개 테스트 실패"
fi
echo "════════════════════════════════════════"

exit "$ERRORS"
