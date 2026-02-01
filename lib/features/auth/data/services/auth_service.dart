import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class AuthService {
  //싱글톤 패턴 (Singleton Pattern) - 엄격한 구현

  //클래스 로드 시점에 단 하나의 인스턴스를 생성
  static final AuthService _instance = AuthService._internal();

  //외부에서는 이 factory 생성자를 통해 언제나 _instance에 접근
  factory AuthService() {
    return _instance;
  }

  //내부 전용 프라이빗 생성자
  AuthService._internal()
      : _storage = const FlutterSecureStorage(),
        _logger = Logger();


  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  final FlutterSecureStorage _storage;
  final Logger _logger;

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080';
  String get _callbackScheme => dotenv.env['CALLBACK_SCHEME'] ?? 'psik';

  // 카카오 로그인
    Future<bool> loginWithKakao() async {
    final url = Uri.parse('$_baseUrl/oauth2/authorization/kakao');

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: _callbackScheme,
        options: const FlutterWebAuth2Options(
          windowName: '_blank',
        ),
      );

      return await _handleAuthResult(result, 'Kakao');

    } on PlatformException catch (e) {
      _logger.i("[Kakao] 사용자 로그인 취소: ${e.code} - ${e.message}");
      return false;
    } catch (e) {
      _logger.e("[Kakao] 예상치 못한 로그인 오류", error: e);
      return false;
    }
  }

  // 구글 로그인
  Future<bool> loginWithGoogle() async {
    final url = Uri.parse('$_baseUrl/oauth2/authorization/google');

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: _callbackScheme,
        options: const FlutterWebAuth2Options(
          windowName: '_blank',
        ),
      );

      return await _handleAuthResult(result, 'Google');

    } on PlatformException catch (e) {
      _logger.i("[Google] 사용자 로그인 취소: ${e.code} - ${e.message}");
      return false;
    } catch (e) {
      _logger.e("[Google] 예상치 못한 로그인 오류", error: e);
      return false;
    }
  }

  // [Private] 토큰 파싱 및 저장 로직
  Future<bool> _handleAuthResult(String resultUrl, String provider) async {
    try {
      final uri = Uri.parse(resultUrl);
      final accessToken = uri.queryParameters[_accessTokenKey];
      final refreshToken = uri.queryParameters[_refreshTokenKey];

      if (accessToken == null || refreshToken == null) {
        _logger.e("[$provider] 토큰 미발급 (URL 파싱 실패). Result: $resultUrl");
        return false;
      }

      await Future.wait([
        _storage.write(key: _accessTokenKey, value: accessToken),
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      ]);

      _logger.i("[$provider] 로그인 성공 및 토큰 저장 완료");
      return true;
    } catch (e) {
      _logger.e("[$provider] 토큰 저장 중 디스크/시스템 오류", error: e);
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _logger.i("로그아웃 완료");
  }
}