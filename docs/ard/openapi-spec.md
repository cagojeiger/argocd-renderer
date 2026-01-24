# OpenAPI Specification Guide

이 문서는 ArgoCD Renderer 프로젝트의 OpenAPI 스펙 작성 기준을 정의합니다.

## 1. OpenAPI 버전

**선택 버전**: OpenAPI 3.1.0

### 선택 이유

1. **JSON Schema 완전 호환**: OpenAPI 3.1.0은 JSON Schema Draft 2020-12와 100% 호환됩니다. 이전 버전(3.0.x)에서 발생하던 `nullable`, `exclusiveMinimum` 등의 불일치 문제가 해결되었습니다.

2. **Webhooks 지원**: 서버에서 클라이언트로 보내는 이벤트를 명시적으로 정의할 수 있어, 향후 ArgoCD 이벤트 기반 확장에 유리합니다.

3. **pathItem 참조**: `$ref`를 통해 path item을 재사용할 수 있어 API 스펙의 중복을 줄입니다.

4. **최신 표준**: 2021년 2월 릴리스 이후 도구 지원이 성숙해졌으며, 주요 API 도구(Swagger UI, Redoc, OpenAPI Generator)가 3.1.0을 지원합니다.

## 2. 공식 스펙 문서

- **OpenAPI 3.1.0 Specification**: https://spec.openapis.org/oas/v3.1.0
- **JSON Schema Draft 2020-12**: https://json-schema.org/draft/2020-12/json-schema-core.html

## 3. 프로젝트 적용 가이드라인

### 3.1 엔드포인트 명명 규칙

| 규칙 | 예시 |
|------|------|
| 소문자와 하이픈(`-`) 사용 | `/render-manifest` |
| 복수형 명사 사용 (컬렉션) | `/repositories`, `/applications` |
| 동사 대신 명사 사용 | `/manifests` (O), `/get-manifests` (X) |
| 리소스 계층 표현 | `/repositories/{repoUrl}/manifests` |
| 버전 접두사 없음 | URL에 `/v1` 등 포함하지 않음 |

**operationId 규칙**:
- camelCase 사용
- `{동사}{리소스}` 형식
- 예: `renderManifest`, `listRepositories`, `healthCheck`

### 3.2 응답 스키마 작성 규칙

**성공 응답 (2xx)**:

```yaml
responses:
  '200':
    description: 명확한 설명 작성
    content:
      application/json:
        schema:
          type: object
          required:
            - 필수_필드_목록
          properties:
            status:
              type: string
              description: 응답 상태
            data:
              type: object
              description: 실제 응답 데이터
```

**스키마 작성 원칙**:
- 모든 필드에 `description` 필수
- `required` 배열로 필수 필드 명시
- `example` 또는 `examples`로 예제 값 제공
- 재사용 가능한 스키마는 `components/schemas`에 정의

### 3.3 에러 응답 형식

모든 에러 응답은 RFC 7807 Problem Details 형식을 따릅니다.

```yaml
components:
  schemas:
    ProblemDetails:
      type: object
      required:
        - type
        - title
        - status
      properties:
        type:
          type: string
          format: uri
          description: 에러 유형을 식별하는 URI
          example: "https://argocd-renderer.io/errors/validation-failed"
        title:
          type: string
          description: 사람이 읽을 수 있는 에러 요약
          example: "Validation Failed"
        status:
          type: integer
          description: HTTP 상태 코드
          example: 400
        detail:
          type: string
          description: 에러에 대한 상세 설명
          example: "The 'repoUrl' field must be a valid Git URL"
        instance:
          type: string
          format: uri
          description: 에러가 발생한 특정 요청 식별자
          example: "/render-manifest/abc123"
```

**HTTP 상태 코드 사용**:

| 코드 | 용도 |
|------|------|
| 400 | 잘못된 요청 (유효성 검사 실패) |
| 401 | 인증 필요 |
| 403 | 권한 없음 (화이트리스트 미등록 등) |
| 404 | 리소스 없음 |
| 500 | 서버 내부 오류 |
| 502 | 업스트림 서비스 오류 |

## 4. 현재 프로젝트 상태

- **스펙 파일 위치**: `api/openapi.yaml`
- **정의된 엔드포인트**: `/healthz` (헬스 체크)
- **서버 URL**: `http://localhost:8080` (로컬 개발)

## 5. 참고 자료

- [OpenAPI Initiative](https://www.openapis.org/)
- [OpenAPI 3.1.0 Release Notes](https://www.openapis.org/blog/2021/02/18/openapi-specification-3-1-released)
- [RFC 7807 - Problem Details for HTTP APIs](https://datatracker.ietf.org/doc/html/rfc7807)
