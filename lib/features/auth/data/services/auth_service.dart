import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:universal_html/html.dart' as html;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal()
      : _storage = const FlutterSecureStorage(),
        _logger = Logger();

  final FlutterSecureStorage _storage;
  final Logger _logger;

  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  // OAuth 시작은 psik.kr 통해 프록시 (세션 쿠키 도메인 일치)
  static const String _oauthBaseUrl = String.fromEnvironment(
    'OAUTH_URL',
    defaultValue: 'http://localhost:8080',
  );



  // ===================== 웹 로그인 (같은 창 리다이렉트) =====================

  /// 카카오 로그인 — 같은 창에서 소셜 로그인 페이지로 이동
  /// 백엔드가 인증 성공 후 /home으로 리다이렉트 + 쿠키에 토큰 세팅
  void loginWithKakaoWeb() {
    if (kIsWeb) {
      html.window.location.assign('$_oauthBaseUrl/oauth2/authorization/kakao');
    }
  }

  /// 구글 로그인 — 같은 창에서 소셜 로그인 페이지로 이동
  void loginWithGoogleWeb() {
    if (kIsWeb) {
      html.window.location.assign('$_oauthBaseUrl/oauth2/authorization/google');
    }
  }

  // ===================== 공통 =====================

  Future<void> logout() async {
    // AccessToken은 메모리에만 있어 AuthProvider가 별도로 비우고,
    // RefreshToken 쿠키는 서버(/api/auth/logout)가 Set-Cookie로 만료시킨다.
    // (httpOnly 쿠키는 여기서 document.cookie로 지우려 해도 브라우저가 무시한다.)
    await _storage.deleteAll();
    _logger.i("로그아웃 완료");
  }
}