import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
// [수정] dart:ui가 아닌 universal_html 사용 — 브라우저 API(window.location) 접근용
import 'package:universal_html/html.dart' as html;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal()
      : _storage = const FlutterSecureStorage(),
        _logger = Logger();

  final FlutterSecureStorage _storage;
  final Logger _logger;

  String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ??
          (kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080');

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