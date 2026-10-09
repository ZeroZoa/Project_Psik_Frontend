import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psik_frontend/features/auth/presentation/providers/auth_provider.dart';

/// /api/members/me 응답을 흉내 내는 가짜 어댑터
/// - [status]로 응답 코드를 지정하고, [connectionError]가 true면 네트워크 오류를 던진다
class _MeAdapter implements HttpClientAdapter {
  _MeAdapter({this.status = 200, this.connectionError = false});

  final int status;
  final bool connectionError;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (connectionError) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'network down',
      );
    }

    final body = status == 200
        ? {
            'profileComplete': true,
            'nickname': '픽이',
            'role': 'USER',
            'uuid': '11111111-1111-1111-1111-111111111111',
            'skinConcerns': <String>[],
          }
        : {'message': '오류'};

    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const storage = FlutterSecureStorage();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'accessToken': 'access',
      'refreshToken': 'refresh',
    });
  });

  Future<AuthProvider> bootWith(_MeAdapter adapter) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;
    final provider = AuthProvider(storage: storage)..setDio(dio);
    await provider.checkLoginStatus();
    return provider;
  }

  group('AuthProvider 부팅 시 사용자 정보 조회', () {
    test('정상 응답이면 로그인 상태와 사용자 정보를 채운다', () async {
      // when
      final provider = await bootWith(_MeAdapter());

      // then
      expect(provider.isAuthenticated, true);
      expect(provider.nickname, '픽이');
      expect(provider.profileComplete, true);
      expect(await storage.read(key: 'refreshToken'), 'refresh');
    });

    test('401이면 인증이 무효이므로 저장된 토큰을 지우고 로그아웃한다', () async {
      // when
      final provider = await bootWith(_MeAdapter(status: 401));

      // then
      expect(provider.isAuthenticated, false);
      expect(await storage.read(key: 'accessToken'), isNull);
      expect(await storage.read(key: 'refreshToken'), isNull);
    });

    test('서버 오류(500)는 일시 장애이므로 저장된 토큰을 보존한다', () async {
      // when
      final provider = await bootWith(_MeAdapter(status: 500));

      // then
      expect(provider.isAuthenticated, false); // 이번 세션은 비로그인 상태
      expect(await storage.read(key: 'accessToken'), 'access');
      expect(await storage.read(key: 'refreshToken'), 'refresh');
    });

    test('네트워크 오류도 일시 장애이므로 저장된 토큰을 보존한다', () async {
      // when
      final provider = await bootWith(_MeAdapter(connectionError: true));

      // then
      expect(provider.isAuthenticated, false);
      expect(await storage.read(key: 'refreshToken'), 'refresh');
    });
  });
}
