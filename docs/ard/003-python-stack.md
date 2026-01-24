# ADR-003: Python 기술 스택 선택

## 상태

Accepted

## 컨텍스트

ArgoCD Renderer 프로젝트의 기술 스택을 결정해야 합니다.

- L7 프록시 서버 및 CLI 도구 개발 필요
- 빠른 개발 속도 vs 런타임 성능 트레이드오프
- 팀의 기술 숙련도 고려

## 결정

### 언어: Python 3.11+

| 후보 | 장점 | 단점 | 선택 |
|------|------|------|------|
| Python | 빠른 개발, 풍부한 라이브러리 | 상대적 저성능 | ✅ |
| Go | 고성능, 단일 바이너리 | 개발 속도 | ❌ |
| Rust | 최고 성능, 메모리 안전 | 학습 곡선 | ❌ |

### 프레임워크 선택

| 용도 | 선택 | 이유 |
|------|------|------|
| 웹 서버 | FastAPI | 비동기, 자동 OpenAPI 문서, 타입 힌트 |
| CLI | Typer | FastAPI 스타일, 자동 --help |
| HTTP 클라이언트 | httpx | 비동기 지원, requests 호환 API |
| 설정 관리 | pydantic-settings | 환경 변수 자동 바인딩 |

### 선택 이유

1. **FastAPI** - OpenAPI 자동 생성으로 API 문서화 용이
2. **Typer** - FastAPI와 동일한 개발 경험
3. **비동기 스택** - I/O 바운드 프록시 작업에 적합

## 결과

### 장점

- 빠른 프로토타이핑 및 개발
- 풍부한 생태계 (테스트, 린팅, 타입 체크)
- OpenAPI 스펙과 코드 동기화

### 단점

- Go/Rust 대비 메모리 사용량 높음
- 콜드 스타트 시간 상대적으로 김

## 참고 자료

- https://fastapi.tiangolo.com/
- https://typer.tiangolo.com/
- https://www.python-httpx.org/
