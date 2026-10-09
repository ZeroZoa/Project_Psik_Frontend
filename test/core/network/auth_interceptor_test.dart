import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psik_frontend/core/network/auth_interceptor.dart';
import 'package:psik_frontend/features/auth/presentation/providers/auth_provider.dart';

/// 서버 대신 응답하는 가짜 어댑터.
/// - /api/auth/reissue → 새 토큰 발급
/// - 그 외 요청 → 새 AccessToken이면 200, 아니면 401 (토큰 만료 상황 재현)
class _FakeServerAdapter implements HttpClientAdapter {
  static const oldAccess = 'old-access';
  static const newAccess = 'new-access';

  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // 실제 전송처럼 본문 스트림을 끝까지 소비한다 (FormData는 이 시점에 finalize됨)
    await requestStream?.drain<void>();

    final auth = options.headers['Authorization'];
    calls.add('${options.method} ${options.path} $auth');

    if (options.path == '/api/auth/reissue') {
      return _json(200, {'accessToken': newAccess, 'refreshToken': 'new-refresh'});
    }
    if (auth == 'Bearer $newAccess') {
      return _json(200, {'ok': true});
    }
    return _json(401, {'message': '만료된 토큰입니다.'});
  }

  @override
  void close({bool force = false}) {}

  ResponseBody _json(int status, Map<String, dynamic> body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  late _FakeServerAdapter adapter;
  late Dio dio;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'accessToken': _FakeServerAdapter.oldAccess,
      'refreshToken': 'old-refresh',
    });

    adapter = _FakeServerAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = adapter;

    final authProvider = AuthProvider(storage: const FlutterSecureStorage());
    final interceptor =
        AuthInterceptor(const FlutterSecureStorage(), dio, authProvider);
    await interceptor.init();
    dio.interceptors.add(interceptor);
  });

  group('AuthInterceptor 401 재발급 후 재시도', () {
    test('FormData(이미지 업로드) 요청도 재발급 후 재시도에 성공한다', () async {
      // given
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes([1, 2, 3], filename: 'face.png'),
      });

      // when
      final response = await dio.post('/upload', data: formData);

      // then
      expect(response.statusCode, 200);
      expect(response.data['ok'], true);
      expect(adapter.calls.where((c) => c.startsWith('POST /upload')).length, 2);
      expect(adapter.calls.where((c) => c.contains('/api/auth/reissue')).length, 1);
    });

    test('JSON 요청은 재발급 후 새 토큰으로 재시도에 성공한다', () async {
      // when
      final response = await dio.post('/diary', data: {'skinScore': 80});

      // then
      expect(response.statusCode, 200);
      expect(adapter.calls.last, 'POST /diary Bearer ${_FakeServerAdapter.newAccess}');
    });
  });
}
