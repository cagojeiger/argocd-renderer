# ADR-002: 화이트리스트 기반 보안 전략

## 상태

Accepted

## 컨텍스트

ArgoCD Renderer 프로젝트의 보안 전략을 결정해야 합니다.

- ArgoCD Renderer는 외부에서 접근 가능한 매니페스트 렌더링 서비스
- Git 저장소 URL을 입력받아 Helm/Kustomize 매니페스트 생성
- 악의적인 저장소 접근 차단 필요
- 인증 기반 vs 화이트리스트 기반 선택 필요

## 결정

### 보안 방식: Open A (화이트리스트)

| 방식 | 설명 | 선택 |
|------|------|------|
| Open A | 인증 없음 + 화이트리스트 | ✅ |
| Closed B | 인증 필수 | ❌ |

### 선택 이유

1. **단순성** - 인증 인프라 불필요
2. **운영 편의** - ConfigMap으로 화이트리스트 관리
3. **보안 충분** - 허용된 저장소만 접근 가능

### 화이트리스트 구현

- Glob 패턴 매칭 (`fnmatch`)
- ConfigMap 기반 설정
- L7 프록시 미들웨어에서 검증

### 보안 레이어

| 레이어 | 구현 |
|--------|------|
| L7 Proxy | repoURL 화이트리스트 검증 |
| NetworkPolicy | Egress 제한 |
| Pod Security | runAsNonRoot, readOnlyRootFilesystem |

## 결과

### 장점

- 인증 시스템 없이 보안 확보
- 운영 단순화 (ConfigMap 수정으로 관리)
- 빠른 요청 처리 (토큰 검증 없음)

### 단점

- 사용자별 접근 제어 불가
- 감사 로그에 사용자 식별 정보 없음

## 참고 자료

- docs/ROADMAP.md 보안 고려사항 섹션
