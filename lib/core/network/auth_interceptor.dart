import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio dio;

  AuthInterceptor(this.storage, this.dio);

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  String? _accessTokenCache;

  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _pendingRequests = [];

  Future<void> init() async {
    _accessTokenCache = await storage.read(key: _accessTokenKey);
  }

  // 1. 요청 전처리
  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    if (options.path.contains('/login') ||
        options.path.contains('/signup') ||
        options.path.contains('/reissue')) {
      return handler.next(options);
    }

    _accessTokenCache ??= await storage.read(key: _accessTokenKey);

    if (_accessTokenCache != null) {
      options.headers['Authorization'] = 'Bearer $_accessTokenCache';
    }

    return handler.next(options);
  }

  // 2. 에러 처리 (401 → 토큰 갱신)
  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // reissue 자체가 401이면 강제 로그아웃
    if (err.requestOptions.path.contains('/reissue')) {
      await _forceLogout();
      return handler.next(err);
    }

    debugPrint('[AuthInterceptor] 토큰 만료 감지.');

    if (_isRefreshing) {
      debugPrint('[AuthInterceptor] 갱신 중... 요청 대기열 추가');
      _pendingRequests.add({
        'options': err.requestOptions,
        'handler': handler,
      });
      return;
    }

    _isRefreshing = true;

    try {
      String? refreshToken;

      if (!kIsWeb) {
        refreshToken = await storage.read(key: _refreshTokenKey);
        if (refreshToken == null) {
          await _forceLogout();
          return handler.next(err);
        }
      }

      // [수정] reissue 요청 — extra에 withCredentials 명시
      final refreshResponse = await dio.post(
        '/api/auth/reissue',
        options: Options(
          // [수정] Authorization을 빈 맵으로 — null 대신 아예 안 보냄
          // onRequest에서 /reissue 경로는 스킵하므로 만료된 토큰이 붙을 일 없음
          headers: {
            // 앱일 때만 헤더로 Refresh Token 전송
            if (!kIsWeb && refreshToken != null) 'Refresh-Token': refreshToken,
          },
          // [핵심 수정] 웹에서 HttpOnly 쿠키(refreshToken)가 전송되려면 필수
          extra: {'withCredentials': true},
        ),
      );

      final newAccessToken = refreshResponse.data['accessToken'];
      final newRefreshToken = refreshResponse.data['refreshToken'];

      if (newAccessToken == null) throw Exception("New Access Token is null");

      _accessTokenCache = newAccessToken;
      await storage.write(key: _accessTokenKey, value: newAccessToken);

      if (!kIsWeb && newRefreshToken != null) {
        await storage.write(key: _refreshTokenKey, value: newRefreshToken);
      }

      debugPrint('[AuthInterceptor] 재발급 성공! 대기열 처리 시작.');

      // 현재 실패했던 요청 재시도
      await _retryRequest(err.requestOptions, handler);

      // 대기열 요청 재시도
      for (var request in _pendingRequests) {
        await _retryRequest(
          request['options'] as RequestOptions,
          request['handler'] as ErrorInterceptorHandler,
        );
      }
    } catch (e) {
      debugPrint('[AuthInterceptor] 재발급 실패: $e');

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

  // [수정] retry 시 원래 요청의 extra(withCredentials 등)도 함께 전달
  Future<void> _retryRequest(
      RequestOptions requestOptions,
      ErrorInterceptorHandler handler,
      ) async {
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $_accessTokenCache', // 새 토큰으로 교체
      },
      extra: {
        ...requestOptions.extra, // 원래 요청의 extra 보존 (withCredentials 등)
      },
    );

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

  Future<void> _forceLogout() async {
    _accessTokenCache = null;
    await storage.deleteAll();
    debugPrint('[AuthInterceptor] 강제 로그아웃 처리됨');
  }
}