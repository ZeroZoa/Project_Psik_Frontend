import 'package:flutter/foundation.dart'; // kIsWeb 사용
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_html/html.dart' as html; // [필수] 웹 쿠키 접근용
import '../../data/services/auth_service.dart';

/// 인증 상태를 관리하는 Provider
/// AuthService(싱글톤)를 통해 소셜 로그인/로그아웃 처리
/// 토큰 키는 AuthService 내부의 storage와 동일한 키를 사용
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FlutterSecureStorage _storage;

  // [수정] 외부에서 주입 가능하도록 생성자 변경 (테스트 용이성 확보)
  // 기본값으로 싱글톤/기본 인스턴스를 사용하여 기존 호출부 호환 유지
  AuthProvider({
    AuthService? authService,
    FlutterSecureStorage? storage,
  })  : _authService = authService ?? AuthService(),
        _storage = storage ?? const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  //* 앱 시작 시 필수 * 토큰이 있는지 확인 (스플래시에서 호출)
  Future<void> checkLoginStatus() async {
    final minSplashDelay = Future.delayed(const Duration(milliseconds: 1200));

    try {
      // [Web 전용 로직] 브라우저 쿠키에서 Access Token을 앱 내부 저장소로 이관
      if (kIsWeb) {
        final cookieAccessToken = _getCookie('accessToken');
        if (cookieAccessToken != null) {
          await _storage.write(key: 'accessToken', value: cookieAccessToken);
          html.document.cookie = "accessToken=; path=/; max-age=0";
        }
      }

      final accessToken = await _storage.read(key: 'accessToken');
      final refreshToken = kIsWeb ? null : await _storage.read(key: 'refreshToken');

      if (kIsWeb) {
        _isAuthenticated = accessToken != null;
      } else {
        _isAuthenticated = accessToken != null && refreshToken != null;
      }
    } catch (e) {
      _isAuthenticated = false;
    } finally {
      await minSplashDelay;
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로그인 버튼 클릭 시 호출
  Future<void> login(Future<bool> Function() loginMethod) async {
    _isLoading = true;
    notifyListeners();

    final isSuccess = await loginMethod();

    if (!kIsWeb) {
      _isAuthenticated = isSuccess;
      _isLoading = false;
      notifyListeners();
    }
  }

  // 로그아웃
  Future<void> logout() async {
    await _authService.logout();

    if (kIsWeb) {
      html.document.cookie = "accessToken=; path=/; max-age=0";
      html.document.cookie = "refreshToken=; path=/; max-age=0";
    }

    _isAuthenticated = false;
    notifyListeners();
  }

  // [Helper] 쿠키 파싱 함수
  String? _getCookie(String name) {
    final cookie = html.document.cookie;
    if (cookie == null || cookie.isEmpty) return null;
    try {
      final entity = cookie.split("; ").firstWhere(
            (item) => item.trim().startsWith("$name="),
        orElse: () => "",
      );
      return entity.isNotEmpty ? entity.split("=")[1] : null;
    } catch (e) {
      return null;
    }
  }
}
