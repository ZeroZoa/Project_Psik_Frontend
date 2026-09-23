---
description: 인증/토큰 흐름 점검 체크리스트 (Psik 프론트엔드)
---

Psik 프론트엔드의 인증 흐름을 점검한다. `CLAUDE.md`의 "핵심 설계 결정 > 인증 토큰 저장 전략" 섹션을 기준으로 아래를 순서대로 확인한다:

1. `auth_interceptor.dart`, `auth_provider.dart`, `auth_service.dart`를 Read로 열어, AccessToken이 여전히 메모리 전용(`_accessTokenCache`)으로만 저장되고 있는지 확인한다.
2. localStorage로 AccessToken이 다시 새어 들어가는 코드가 없는지 확인한다:
   `grep -rn "localStorage" lib/`
3. 새로고침/부팅 흐름(`_tryReissueOnBoot`)이 여전히 `/api/auth/reissue`를 호출해 RefreshToken 쿠키로 재발급받는 구조인지 확인한다.
4. 로그아웃/탈퇴/강제로그아웃 3곳 모두 `_authInterceptor?.clearAccessTokenInMemory()`를 호출하는지 확인한다.
5. 발견한 문제를 실무 기준 심각도(상/중/하)로 정리해서 보고한다. **코드는 직접 수정하지 않고 스니펫만 제공한다.**
