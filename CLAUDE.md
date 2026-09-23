# Psik Frontend

화장품 성분 분석 서비스의 Flutter Web/Mobile 클라이언트.

## 기술 스택

- Flutter SDK ^3.8.0 (Web 우선, 모바일 동시 지원)
- 상태관리: Provider
- 라우팅: go_router 17.x
- HTTP: Dio 5.9.x
- 보안 저장소: flutter_secure_storage 10.x (모바일 전용)
- OAuth 웹뷰: flutter_web_auth_2, flutter_inappwebview
- 이미지: image_picker
- 차트: fl_chart
- 배포: Firebase Hosting

## Commands
- Run (web): `flutter run -d chrome --dart-define=API_URL=http://localhost:8080`
- Analyze: `flutter analyze`
- Test: `flutter test`

## 디렉토리 구조 (feature-based)

```
lib/
├── core/
│   ├── router/app_router.dart   (go_router, ShellRoute + 하단 네비게이션)
│   └── network/                 (api_error_handler.dart, auth_interceptor.dart)
├── common/
│   ├── theme/
│   └── widgets/
└── features/
    ├── admin, auth, chat, community, diary,
    │   home, mypage, search, splash
    └── (각 feature: data/{models,repositories,services} + presentation/{providers,view,widgets})
```

## 핵심 설계 결정 (Why)

### 인증 토큰 저장 전략 (2026-09-12 개선)
- **AccessToken**: 브라우저 `localStorage`에 저장하던 방식 → **메모리 전용**(`AuthInterceptor._accessTokenCache`)으로 전환. 이유: localStorage는 페이지 내 모든 JS가 읽을 수 있어 XSS 발생 시 그대로 탈취되는 구조였음.
- **부팅/새로고침 시**: `AuthProvider._tryReissueOnBoot()`가 `/api/auth/reissue`를 호출해 RefreshToken(httpOnly 쿠키)으로 AccessToken을 재발급받아 메모리에 채움. 로그인 직후 OAuth 리다이렉트도 이제 토큰 없이 이동만 하고, 이 부팅 흐름으로 통일해서 처리.
- **모바일(non-web)**: AccessToken/RefreshToken 모두 `flutter_secure_storage` 사용 (Keychain/Keystore라 안전, 변경 안 함).
- 설계 원칙: "지속 저장이 필요한 값은 httpOnly 쿠키(RefreshToken) 하나로 한정, AccessToken은 매번 재발급받는 소모성 값으로 취급."
- AccessToken을 쿠키로 안 하고 굳이 메모리+헤더 방식을 쓰는 이유: 쿠키는 브라우저가 모든 요청에 자동 첨부하므로 CSRF 공격 표면이 API 전체로 넓어짐. Authorization 헤더는 공격자가 토큰 값을 알아야 위조 가능해 CSRF에 안전함.

### 네트워크 레이어
`AuthInterceptor`(Dio interceptor) — 요청 시 메모리 캐시된 AccessToken을 `Authorization: Bearer`로 첨부, 401 응답 시 자동으로 `/api/auth/reissue` 후 재시도. `AuthProvider`와 상호 참조(`setAuthInterceptor`)해 로그아웃 시 메모리 캐시도 즉시 비움.

### 라우팅
go_router 기반 `_ShellScaffold` — 하단 네비게이션 바가 80px 스크롤마다 자동 숨김/노출.

## Core Rules

- 상태관리는 `Provider` — `ChangeNotifier` 상속, private 필드 + public getter, 상태 변경 직후 `notifyListeners()` 호출.
- Repository는 생성자로 `Dio` 인스턴스를 주입받는다 (예: `CosmeticsRepository(dio)`). `main.dart`에서 전부 생성 후 `MultiProvider`로 등록.
- API 통신은 반드시 `Dio` 경유 — `http` 패키지나 별도 클라이언트를 새로 만들지 않는다.
- 인증 토큰: **AccessToken은 절대 `localStorage`/파일 등 영속 저장소에 쓰지 않는다** (메모리 전용 원칙 — `AuthInterceptor._accessTokenCache`).
- `kIsWeb` 분기가 필요한 코드는 web/모바일 양쪽 동작을 항상 같이 고려한다.

## 테스트 전략

**현재 상태**: 테스트 없음 (`test/widget_test.dart`는 보일러플레이트, 로직 전부 주석 처리됨).

**원칙**: Flutter 위젯 테스트는 비용 대비 효율이 낮은 경우가 많아, Provider/Repository 단위 테스트부터 우선 도입 권장.

**컨벤션** (새로 작성 시 적용):
- `flutter_test`의 `group`/`test` 사용, mock은 필요 최소한으로
- 위젯 테스트보다 Provider/Repository 단위 테스트 우선

**실행**: `flutter test`

## 코드 리뷰 체크리스트

- [ ] `kIsWeb` 분기가 모바일/웹 양쪽 다 고려됐는가
- [ ] 인증 관련 코드에서 AccessToken이 localStorage로 다시 새어 들어가지 않는가 (메모리 전용 원칙 준수)
- [ ] Provider의 `notifyListeners()` 호출 위치가 상태 변경 직후인가
- [ ] Dio 에러 처리가 `AuthInterceptor`/`ApiErrorHandler`를 우회하지 않는가

## 디버깅 가이드

- 로컬 실행: `flutter run -d chrome --dart-define=API_URL=http://localhost:8080`
- 네트워크 확인: 브라우저 DevTools Network 탭 (Dio 로깅 인터셉터 추가 고려 가능)
- 인증 이슈 디버깅: `AuthInterceptor`/`AuthProvider`의 `debugPrint` 로그 확인

## 브랜치 전략 & 배포

- `develop`: push 시 빌드 검증만 (`frontend-ci.yml`)
- `main`: push 시 Flutter 빌드 → Firebase Hosting 배포 (`frontend-deploy.yml`)
- API 연결: `--dart-define=API_URL=https://api.psik.kr`, `--dart-define=OAUTH_URL=https://api.psik.kr`

## 작업 규칙

- **코드는 직접 수정하지 않고 스니펫만 제공한다.** 사용자가 명시적으로 "이번엔 네가 수정해줘"라고 말할 때만 예외.
- **git add/commit/push도 항상 사용자가 직접 한다.** AI는 실행할 명령어와 커밋 메시지만 제공하고, 별도 지시("커밋까지 해줘" 등) 없으면 절대 직접 커밋/푸시하지 않는다.
- 커밋 메시지는 `type: 설명` 스타일. 타입: `feat`, `fix`, `docs`, `perf`, `chore`.

## 알려진 기술 부채

- (백엔드와 연동된 이슈이므로 `psik_backend/CLAUDE.md`의 "알려진 기술 부채" 참고)
