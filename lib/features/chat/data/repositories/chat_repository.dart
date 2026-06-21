import 'package:dio/dio.dart';

class ChatRepository {
  final Dio _dio;

  ChatRepository(this._dio);

  Future<String> sendMessage(String message) async {
    try {
      final response = await _dio.post(
        '/api/chat',
        data: {'message': message},
      );
      return response.data['answer'] as String;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('로그인이 필요한 서비스입니다.');
      }
      throw Exception('답변 조회 실패: ${e.message}');
    } catch (e) {
      throw Exception('답변 조회 실패: $e');
    }
  }
}