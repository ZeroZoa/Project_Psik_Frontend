import 'package:dio/dio.dart';

class ChatRepository {
  final Dio _dio;

  ChatRepository(this._dio);

  Future<String> sendMessage(String message) async {
    final response = await _dio.post(
      '/api/chat',
      data: {'message': message},
    );
    return response.data['answer'] as String;
  }
}
