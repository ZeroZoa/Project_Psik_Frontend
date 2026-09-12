import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/services/auth_service.dart';
import '../../domain/enums/skin_concern.dart';
import '../../../../core/network/auth_interceptor.dart';

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
  AuthInterceptor? _authInterceptor;

  AuthProvider({
    AuthService? authService,
    FlutterSecureStorage? storage,
  })  : _authService = authService ?? AuthService(),
        _storage = storage ?? const FlutterSecureStorage();

  void setDio(Dio dio) {
    _dio = dio;
  }

  /// main.dart에서 AuthInterceptor 생성 직후 연결 — Web에서 재발급받은
  /// AccessToken을 인터셉터의 메모리 캐시에 반영하기 위해 필요.
  void setAuthInterceptor(AuthInterceptor interceptor) {
    _authInterceptor = interceptor;
  }

  // ── 앱 시작 시 로그인 상태 확인 ──
  Future<void> checkLoginStatus() async {
    try {
      if (kIsWeb) {
        // Web은 AccessToken을 어디에도 영속 저장하지 않으므로, 매 부팅(새로고침)마다
        // RefreshToken(httpOnly 쿠키)으로 재발급받아 로그인 여부를 판단한다.
        _isAuthenticated = await _tryReissueOnBoot();
      } else {
        final accessToken = await _storage.read(key: 'accessToken');
        final refreshToken = await _storage.read(key: 'refreshToken');
        _isAuthenticated = accessToken != null && refreshToken != null;
      }

      if (_isAuthenticated && _dio != null) {
        await _fetchUserInfo();
      }
    } catch (e) {
      debugPrint('[AuthProvider] checkLoginStatus 실패: $e');
      _resetState();
    } finally {
      notifyListeners();
    }
  }

  /// Web 전용 — RefreshToken 쿠키로 AccessToken을 재발급받아 메모리 캐시에 채운다.
  /// 쿠키가 없거나 만료됐으면 false(비로그인 상태)를 반환한다.
  Future<bool> _tryReissueOnBoot() async {
    if (_dio == null) return false;
    try {
      final response = await _dio!.post(
        '/api/auth/reissue',
        options: Options(extra: {'withCredentials': true}),
      );
      final accessToken = response.data['accessToken'] as String?;
      if (accessToken == null) return false;
      _authInterceptor?.setAccessTokenInMemory(accessToken);
      return true;
    } on DioException catch (e) {
      debugPrint('[AuthProvider] 부팅 시 재발급 실패(비로그인으로 간주): ${e.response?.statusCode}');
      return false;
    }
  }

  // ── 유저 정보 새로고침
  Future<void> refreshUserInfo() async {
    if (!_isAuthenticated || _dio == null) return;
    try {
      await _fetchUserInfo();
      notifyListeners();
    } on DioException catch (e) {
      debugPrint('[AuthProvider] refreshUserInfo 실패: ${e.response?.statusCode}');
    } catch (e) {
      debugPrint('[AuthProvider] refreshUserInfo 실패: $e');
    }
  }

// ── /api/members/me 공통 로직 ──
  Future<void> _fetchUserInfo() async {
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
      debugPrint('[AuthProvider] /api/members/me 실패: ${e.response?.statusCode}');
      await _authService.logout();
      _resetState();
    } catch (e) {
      debugPrint('[AuthProvider] profileComplete 조회 실패: $e');
      _profileComplete = false;
      _skinConcerns = [];
      _role = null;
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
    _authInterceptor?.clearAccessTokenInMemory();
    _resetState();
    notifyListeners();
  }

  // ── 회원 탈퇴 ──
  Future<bool> withdraw() async {
    try {
      await _dio?.delete('/api/members/me');
      await _authService.logout();
      _authInterceptor?.clearAccessTokenInMemory();
      _resetState();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthProvider] 회원 탈퇴 실패: $e');
      return false;
    }
  }

  // ── 강제 로그아웃 (토큰 만료/재발급 실패 시) ──
  Future<void> forceLogout() async {
    await _authService.logout();
    _authInterceptor?.clearAccessTokenInMemory();
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
}