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


  // ===================== 웹 로그인 (같은 창 리다이렉트) =====================

  /// 카카오 로그인 — 같은 창에서 소셜 로그인 페이지로 이동
  /// 백엔드가 인증 성공 후 /home으로 리다이렉트 + 쿠키에 토큰 세팅
  void loginWithKakaoWeb() {
    if (kIsWeb) {
      html.window.location.assign('$_baseUrl/oauth2/authorization/kakao');
    }
  }

  /// 구글 로그인 — 같은 창에서 소셜 로그인 페이지로 이동
  void loginWithGoogleWeb() {
    if (kIsWeb) {
      html.window.location.assign('$_baseUrl/oauth2/authorization/google');
    }
  }

  // ===================== 공통 =====================

  Future<void> logout() async {
    await _storage.deleteAll();

    if (kIsWeb) {
      html.document.cookie = "accessToken=; path=/; max-age=0";
      html.document.cookie = "refreshToken=; path=/; max-age=0";
    }

    _logger.i("로그아웃 완료");
  }
}