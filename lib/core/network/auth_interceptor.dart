import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // kIsWeb 사용을 위해 필수
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio dio;

  AuthInterceptor(this.storage, this.dio);

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  // [최적화 1] 메모리 캐시: 매번 느린 스토리지(Disk)에서 읽지 않도록 함
  String? _accessTokenCache;

  // [최적화 2] 동시성 제어: 토큰 갱신 중인지 확인하는 플래그
  bool _isRefreshing = false;

  // [최적화 2] 대기열: 갱신 중일 때 들어온 요청들을 모아두는 리스트
  final List<Map<String, dynamic>> _pendingRequests = [];

  // 앱 시작 시 한 번만 호출해서 캐시 초기화 권장 (main.dart 등에서 await authInterceptor.init())
  Future<void> init() async {
    _accessTokenCache = await storage.read(key: _accessTokenKey);
  }

  // 1. 요청 전처리 (Header에 Access Token 넣기)
  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    // 로그인, 회원가입, 재발급 요청에는 토큰을 넣지 않음
    if (options.path.contains('/login') ||
        options.path.contains('/signup') ||
        options.path.contains('/reissue')) {
      return handler.next(options);
    }

    // [최적화 1 적용] 메모리 캐시 우선 사용, 없으면 스토리지 조회 (Fail-safe)
    _accessTokenCache ??= await storage.read(key: _accessTokenKey);

    if (_accessTokenCache != null) {
      options.headers['Authorization'] = 'Bearer $_accessTokenCache';
    }

    return handler.next(options);
  }

  // 2. 에러 처리 (401 발생 시 토큰 갱신 로직)
  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    // 401 에러가 아니면 그냥 통과
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // 재발급 요청 자체가 401이면 강제 로그아웃 (무한 루프 방지)
    if (err.requestOptions.path.contains('/reissue')) {
      await _forceLogout();
      return handler.next(err);
    }

    debugPrint('[AuthInterceptor] 토큰 만료 감지.');

    // [최적화 2 적용] 이미 갱신 중이라면? -> 대기열에 넣고 리턴 (API 중복 호출 방지)
    if (_isRefreshing) {
      debugPrint('[AuthInterceptor] 갱신 중... 요청 대기열 추가');
      final completer = Completer<Response>();
      _pendingRequests.add({
        'completer': completer,
        'options': err.requestOptions, // 실패했던 요청 정보
        'handler': handler,
      });
      return;
    }

    _isRefreshing = true;

    try {
      String? refreshToken;

      // [핵심] 앱(App)일 때만 스토리지에서 Refresh Token 확인
      // 웹(Web)은 쿠키(HttpOnly)에 있으므로 자바스크립트로 읽을 수 없음 -> 브라우저가 알아서 보냄
      if (!kIsWeb) {
        refreshToken = await storage.read(key: _refreshTokenKey);
        if (refreshToken == null) {
          // 앱인데 리프레시 토큰이 없으면 로그아웃
          await _forceLogout();
          return handler.next(err);
        }
      }

      // 토큰 갱신 API 호출
      // [주의] dio.post 사용 시 인터셉터가 또 걸리지 않게 path 체크(onRequest)가 필수임
      final refreshResponse = await dio.post(
        '/api/auth/reissue',
        options: Options(
          headers: {
            'Authorization': null, // 기존 만료된 토큰 제거
            // [앱일 때만] 헤더에 Refresh Token 추가 (웹은 쿠키가 자동 전송됨)
            if (!kIsWeb && refreshToken != null) 'Refresh-Token': refreshToken,
          },
        ),
      );

      final newAccessToken = refreshResponse.data['accessToken'];
      final newRefreshToken = refreshResponse.data['refreshToken'];

      if (newAccessToken == null) throw Exception("New Access Token is null");

      // [중요] 캐시 및 스토리지 갱신
      _accessTokenCache = newAccessToken; // 메모리 갱신
      await storage.write(key: _accessTokenKey, value: newAccessToken);

      // [앱일 때만] 새 Refresh Token 저장 (웹은 Set-Cookie로 브라우저가 갱신)
      if (!kIsWeb && newRefreshToken != null) {
        await storage.write(key: _refreshTokenKey, value: newRefreshToken);
      }

      debugPrint('[AuthInterceptor] 재발급 성공! 대기열 처리 시작.');

      // 1. 현재 실패했던 요청 재시도
      _retryRequest(err.requestOptions, handler);

      // 2. 대기열에 있던 요청들 모두 재시도
      for (var request in _pendingRequests) {
        _retryRequest(
          request['options'] as RequestOptions,
          request['handler'] as ErrorInterceptorHandler,
        );
      }
    } catch (e) {
      debugPrint('[AuthInterceptor] 재발급 실패: $e');

      // 갱신 실패 시 대기열의 모든 요청도 에러 처리
      for (var request in _pendingRequests) {
        (request['handler'] as ErrorInterceptorHandler).reject(err);
      }
      await _forceLogout();
      return handler.next(err);
    } finally {
      _pendingRequests.clear();
      _isRefreshing = false;
    }
  }

  // 요청 재시도 헬퍼 함수
  Future<void> _retryRequest(
      RequestOptions requestOptions,
      ErrorInterceptorHandler handler,
      ) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    // 새 토큰으로 교체
    options.headers?['Authorization'] = 'Bearer $_accessTokenCache';

    try {
      final response = await dio.request<dynamic>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options,
      );
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  // 강제 로그아웃 (저장소 및 메모리 비우기)
  Future<void> _forceLogout() async {
    _accessTokenCache = null;
    await storage.deleteAll();
    debugPrint('[AuthInterceptor] 강제 로그아웃 처리됨');
  }
}