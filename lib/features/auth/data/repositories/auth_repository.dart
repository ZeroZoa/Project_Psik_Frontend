import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response_model.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage; //토큰 저장을 위한 저장소

  // 생성자 주입 (main.dart에서 주입해줌)
  AuthRepository(this._dio, this._storage);

  /// 로그인 API
  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      // 1. JSON 파싱
      final authResponse = AuthResponse.fromJson(response.data);

      // 2. [핵심] 토큰을 내부 저장소에 안전하게 저장 (앱 꺼도 유지됨)
      await _storage.write(key: 'accessToken', value: authResponse.accessToken);
      await _storage.write(key: 'refreshToken', value: authResponse.refreshToken);

    } on DioException catch (e) {
      // 3. 에러 핸들링 세분화
      if (e.response != null) {
        // 서버가 에러 응답(400, 401, 403 등)을 보낸 경우
        // Spring 백엔드가 보내주는 에러 메시지("비밀번호가 틀렸습니다" 등)를 그대로 보여줌
        throw Exception(e.response?.data['message'] ?? '로그인에 실패했습니다.');
      } else {
        // 서버 연결 자체가 안 된 경우 (네트워크 끊김, 서버 다운)
        throw Exception('서버와 연결할 수 없습니다. 인터넷을 확인해주세요.');
      }
    }
  }

  /// 회원가입 API
  Future<void> signUp(String email, String password, String nickname) async {
    try {
      await _dio.post(
        '/api/auth/signup',
        data: {
          'email': email,
          'password': password,
          'nickname': nickname, // Spring DTO 필드명 확인 필요 (보통 nickname or username)
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        // "이미 존재하는 이메일입니다" 등의 메시지 처리
        throw Exception(e.response?.data['message'] ?? '회원가입에 실패했습니다.');
      } else {
        throw Exception('서버와 연결할 수 없습니다.');
      }
    }
  }

  /// [추가] 로그아웃 (토큰 삭제)
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}