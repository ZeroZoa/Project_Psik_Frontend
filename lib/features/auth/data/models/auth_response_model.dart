class AuthResponse {
  final String accessToken;
  final String refreshToken;

  //생성자
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  //JSON 파싱 팩토리 메서드
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      // [방어 코드] Spring 백엔드에서 null이 오거나 키값이 달라도 앱이 죽지 않도록 처리
      // as String? : 혹시 타입이 다를 경우를 대비
      // ?? '' : null일 경우 빈 문자열 반환
      accessToken: (json['accessToken'] as String?) ?? '',
      refreshToken: (json['refreshToken'] as String?) ?? '',
    );
  }

  //디버깅용 toString 오버라이드
  @override
  String toString() {
    return 'AuthResponse(accessToken: ${accessToken.substring(0, 5)}..., refreshToken: present)';
  }
}