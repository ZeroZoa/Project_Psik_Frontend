import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal()
      : _storage = const FlutterSecureStorage(),
        _logger = Logger();

  final FlutterSecureStorage _storage;
  final Logger _logger;

  // [수정] Web 개발 시 localhost 사용 (에뮬레이터는 10.0.2.2)
  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? (kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080');

  // [수정] Web에서는 'http' 스킴 사용
  String get _callbackScheme => kIsWeb ? 'http' : (dotenv.env['CALLBACK_SCHEME'] ?? 'psik');

  // 카카오 로그인
  Future<bool> loginWithKakao() async {
    final url = Uri.parse('$_baseUrl/oauth2/authorization/kakao');
    return await _authenticate(url, 'Kakao');
  }

  // 구글 로그인
  Future<bool> loginWithGoogle() async {
    final url = Uri.parse('$_baseUrl/oauth2/authorization/google');
    return await _authenticate(url, 'Google');
  }

  // 공통 인증 로직
  Future<bool> _authenticate(Uri url, String provider) async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: _callbackScheme,
        options: const FlutterWebAuth2Options(
          windowName: '_blank', // 웹에서 새 탭으로 열기
        ),
      );

      return await _handleAuthResult(result, provider);

    } on PlatformException catch (e) {
      _logger.i("[$provider] 사용자 로그인 취소: ${e.code}");
      return false;
    } catch (e) {
      _logger.e("[$provider] 로그인 오류", error: e);
      return false;
    }
  }

  // [핵심 로직] 토큰 파싱 및 저장
  Future<bool> _handleAuthResult(String resultUrl, String provider) async {
    try {
      final uri = Uri.parse(resultUrl);
      final accessToken = uri.queryParameters['accessToken'];
      final refreshToken = uri.queryParameters['refreshToken']; // 'COOKIE' 값으로 들어옴

      if (accessToken == null) {
        _logger.e("[$provider] Access Token 없음");
        return false;
      }

      // 1. Access Token 저장
      await _storage.write(key: 'accessToken', value: accessToken);

      // 2. Refresh Token 저장 (앱일 때만)
      // 웹은 쿠키에 있으므로 'COOKIE' 값으로 들어오면 저장을 건너뜁니다.
      if (!kIsWeb && refreshToken != null && refreshToken != 'COOKIE') {
        await _storage.write(key: 'refreshToken', value: refreshToken);
      }

      _logger.i("[$provider] 로그인 성공 (Web Mode)");
      return true;
    } catch (e) {
      _logger.e("[$provider] 에러 발생", error: e);
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _logger.i("로그아웃 완료");
  }
}