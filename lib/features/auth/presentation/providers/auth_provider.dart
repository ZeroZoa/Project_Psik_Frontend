import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_html/html.dart' as html;
import '../../data/services/auth_service.dart';
import '../../domain/enums/skin_concern.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FlutterSecureStorage _storage;

  // ── 사용자 정보 ──
  String _nickname = '';
  String get nickname => _nickname;

  String? _memberUuid;
  String? get memberUuid => _memberUuid;

  List<SkinConcern> _skinConcerns = [];
  List<SkinConcern> get skinConcerns => _skinConcerns;

  // ── Role ──
  // 기본값 null → isAdmin 기본 false 보장
  // 백엔드 Jackson은 Enum.name() 기준으로 직렬화하므로 "ADMIN"으로 내려옴
  // 만약 "ROLE_ADMIN"으로 내려온다면 isAdmin getter를 _role == 'ROLE_ADMIN'으로 수정
  String? _role;
  String? get role => _role;

  /// UI 표시 전용 — 실제 보안은 백엔드 @PreAuthorize가 담당
  bool get isAdmin => _isAuthenticated && _role == 'ADMIN';

  // ── 인증 상태 ──
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _profileComplete = false;
  bool get profileComplete => _profileComplete;

  Dio? _dio;

  AuthProvider({
    AuthService? authService,
    FlutterSecureStorage? storage,
  })  : _authService = authService ?? AuthService(),
        _storage = storage ?? const FlutterSecureStorage();

  void setDio(Dio dio) {
    _dio = dio;
  }

  // ── 앱 시작 시 로그인 상태 확인 ──
  Future<void> checkLoginStatus() async {
    try {
      if (kIsWeb) {
        final cookieAccessToken = _getCookie('accessToken');
        if (cookieAccessToken != null) {
          await _storage.write(key: 'accessToken', value: cookieAccessToken);
          html.document.cookie = "accessToken=; path=/; max-age=0";
        }
      }

      final accessToken = await _storage.read(key: 'accessToken');

      if (kIsWeb) {
        _isAuthenticated = accessToken != null;
      } else {
        final refreshToken = await _storage.read(key: 'refreshToken');
        _isAuthenticated = accessToken != null && refreshToken != null;
      }

      if (_isAuthenticated && _dio != null) {
        try {
          final response = await _dio!.get('/api/members/me');
          final data = response.data as Map<String, dynamic>;

          _profileComplete = data['profileComplete'] as bool? ?? false;
          _nickname = data['nickname'] as String? ?? '';
          _role = data['role'] as String?;
          _memberUuid = data['uuid'] as String?;

          final rawConcerns = data['skinConcerns'] as List<dynamic>? ?? [];
          _skinConcerns = rawConcerns
              .map((e) => SkinConcern.values.byName(e as String))
              .toList();

          debugPrint('[AuthProvider] role=$_role, isAdmin=$isAdmin');
        } on DioException catch (e) {
          debugPrint(
              '[AuthProvider] /api/members/me 실패: ${e.response?.statusCode}');
          await _authService.logout();
          _resetState();
        } catch (e) {
          debugPrint('[AuthProvider] profileComplete 조회 실패: $e');
          _profileComplete = false;
          _skinConcerns = [];
          _role = null;
        }
      }
    } catch (e) {
      debugPrint('[AuthProvider] checkLoginStatus 실패: $e');
      _resetState();
    } finally {
      notifyListeners();
    }
  }

  // ── 로그아웃 ──
  Future<void> logout() async {
    try {
      await _dio?.post('/api/auth/logout');
    } catch (e) {
      debugPrint('[AuthProvider] 로그아웃 API 실패 (무시): $e');
    }
    await _authService.logout();
    _resetState();
    notifyListeners();
  }

  // ── 강제 로그아웃 (토큰 만료/재발급 실패 시) ──
  Future<void> forceLogout() async {
    await _authService.logout();
    _resetState();
    notifyListeners();
    debugPrint('[AuthProvider] 강제 로그아웃 → isAuthenticated = false');
  }

  // ── 프로필 설정 완료 후 상태 직접 업데이트 ──
  void onProfileSetupComplete(List<SkinConcern> concerns, String nickname) {
    _profileComplete = true;
    _skinConcerns = concerns;
    _nickname = nickname;
    notifyListeners();
  }

  /// 피부 고민 업데이트 후 상태 반영
  void onSkinConcernsUpdated(List<SkinConcern> concerns) {
    _skinConcerns = concerns;
    notifyListeners();
  }

  // ── 상태 초기화 공통 메서드 ──
  void _resetState() {
    _isAuthenticated = false;
    _profileComplete = false;
    _nickname = '';
    _skinConcerns = [];
    _role = null;
    _memberUuid = null;
  }

  // ── 쿠키 파싱 헬퍼 ──
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