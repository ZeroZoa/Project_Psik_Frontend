import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio dio; // 재요청을 위해 Dio 인스턴스가 필요합니다.

  AuthInterceptor(this.storage, this.dio);

  // 1. 요청 전처리 (Header에 토큰 넣기)
  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    // [예외 처리] 로그인, 회원가입, 토큰 재발급 요청에는 토큰을 넣지 않습니다.
    if (options.path.contains('/login') ||
        options.path.contains('/signup') ||
        options.path.contains('/reissue')) { // Spring 엔드포인트에 맞춰 수정 필요
      return handler.next(options);
    }

    // 저장소에서 Access Token 읽기
    final accessToken = await storage.read(key: 'ACCESS_TOKEN');

    if (accessToken != null) {
      // 실무 표준: Bearer 스키마 사용
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  //에러 처리 (토큰 만료 시 갱신 로직)
  @override
  Future<void> onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    // 401 에러가 아니면 그냥 통과
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    //이미 토큰 재발급을 시도하다가 401이 난 경우라면 로그아웃
    if (err.requestOptions.path.contains('/reissue')) {
      await _forceLogout();
      return handler.next(err);
    }

    debugPrint('[AuthInterceptor] Access Token 만료됨. 재발급 시도...');

    try {
      //Refresh Token 읽어오기
      final refreshToken = await storage.read(key: 'REFRESH_TOKEN');

      if (refreshToken == null) {
        // Refresh Token이 아예 없으면 로그아웃
        await _forceLogout();
        return handler.next(err);
      }

      //토큰 재발급 API 호출 (새로운 Dio 객체 생성 권장 or 기존 Dio 사용 시 Header 주의)
      final refreshResponse = await dio.post(
        '/api/auth/reissue', // Spring 백엔드의 재발급 경로 (확인 필요)
        data: {
          'refreshToken': refreshToken, // Body로 보내는지 Header로 보내는지 백엔드 명세 확인
        },
        options: Options(
          headers: {'Authorization': null}, // 기존 토큰 헤더 제거
        ),
      );

      // 3. 새 토큰 저장
      final newAccessToken = refreshResponse.data['accessToken'];
      final newRefreshToken = refreshResponse.data['refreshToken'];

      await storage.write(key: 'ACCESS_TOKEN', value: newAccessToken);
      if (newRefreshToken != null) {
        await storage.write(key: 'REFRESH_TOKEN', value: newRefreshToken);
      }

      debugPrint('[AuthInterceptor] 토큰 재발급 성공! 원래 요청 재시도.');

      //실패했던 원래 요청의 헤더를 새 토큰으로 교체
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newAccessToken';

      // 원래 요청 재전송
      final clonedRequest = await dio.fetch(options);

      //성공한 재요청 결과를 반환 (앱은 401이 났었는지 모름)
      return handler.resolve(clonedRequest);

    } catch (e) {
      // Refresh Token도 만료되었거나 서버가 거부한 경우
      debugPrint('[AuthInterceptor] Refresh Token 만료 또는 재발급 실패: $e');
      await _forceLogout();
      return handler.next(err); // 에러를 그대로 전달
    }
  }

  //강제 로그아웃 처리
  Future<void> _forceLogout() async {
    await storage.deleteAll();
    // TODO: 로그인 화면으로 이동하는 전역 로직 필요 (NavigatorKey 사용 등)
    // 지금은 일단 저장소만 비웁니다.
  }
}