import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_html/html.dart' as html;
import '../../features/auth/presentation/providers/auth_provider.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio dio;
  final AuthProvider authProvider;

  AuthInterceptor(this.storage, this.dio, this.authProvider);

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  String? _accessTokenCache;
  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _pendingRequests = [];

  // ── 웹/앱 토큰 읽기/쓰기/삭제 헬퍼 ──
  Future<String?> _readAccessToken() async {
    if (kIsWeb) return html.window.localStorage[_accessTokenKey];
    return await storage.read(key: _accessTokenKey);
  }

  Future<void> _writeAccessToken(String token) async {
    if (kIsWeb) {
      html.window.localStorage[_accessTokenKey] = token;
    } else {
      await storage.write(key: _accessTokenKey, value: token);
    }
  }

  void _deleteAccessToken() {
    if (kIsWeb) {
      html.window.localStorage.remove(_accessTokenKey);
    }
    // 앱은 _forceLogout에서 authProvider.forceLogout → authService.logout → storage.deleteAll
  }

  Future<void> init() async {
    _accessTokenCache = await _readAccessToken();
  }

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

    _accessTokenCache ??= await _readAccessToken();

    if (_accessTokenCache != null) {
      options.headers['Authorization'] = 'Bearer $_accessTokenCache';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (err.requestOptions.path.contains('/reissue')) {
      await _forceLogout();
      return handler.next(err);
    }

    debugPrint('[AuthInterceptor] 토큰 만료 감지.');

    if (_isRefreshing) {
      _pendingRequests.add({'options': err.requestOptions, 'handler': handler});
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

      final refreshResponse = await dio.post(
        '/api/auth/reissue',
        options: Options(
          headers: {
            if (!kIsWeb && refreshToken != null) 'Refresh-Token': refreshToken,
          },
          extra: {'withCredentials': true},
        ),
      );

      final newAccessToken = refreshResponse.data['accessToken'] as String?;
      final newRefreshToken = refreshResponse.data['refreshToken'] as String?;

      if (newAccessToken == null) throw Exception('New Access Token is null');

      _accessTokenCache = newAccessToken;
      await _writeAccessToken(newAccessToken);

      if (!kIsWeb && newRefreshToken != null) {
        await storage.write(key: _refreshTokenKey, value: newRefreshToken);
      }

      debugPrint('[AuthInterceptor] 재발급 성공! 대기열 처리 시작.');

      await _retryRequest(err.requestOptions, handler);
      for (final req in _pendingRequests) {
        await _retryRequest(
          req['options'] as RequestOptions,
          req['handler'] as ErrorInterceptorHandler,
        );
      }
    } catch (e) {
      debugPrint('[AuthInterceptor] 재발급 실패: $e');
      for (final req in _pendingRequests) {
        (req['handler'] as ErrorInterceptorHandler).reject(err);
      }
      await _forceLogout();
      return handler.next(err);
    } finally {
      _pendingRequests.clear();
      _isRefreshing = false;
    }
  }

  Future<void> _retryRequest(
      RequestOptions requestOptions,
      ErrorInterceptorHandler handler,
      ) async {
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $_accessTokenCache',
      },
      extra: {...requestOptions.extra},
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
    _deleteAccessToken();
    await authProvider.forceLogout();
    debugPrint('[AuthInterceptor] 강제 로그아웃 처리됨');
  }
}