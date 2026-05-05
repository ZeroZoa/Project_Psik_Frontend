import 'package:dio/dio.dart';

class ApiErrorHandler {
  /// Dio 에러 → 사용자에게 보여줄 한국어 메시지 반환
  /// 백엔드 ErrorResponse.message가 있으면 그대로 사용
  static String getMessage(Object e) {
    if (e is DioException) {
      // 백엔드 ErrorResponse.message 우선 사용
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'];
      }
      return switch (e.response?.statusCode) {
        400 => '잘못된 요청입니다.',
        401 => '로그인이 필요합니다.',
        403 => '접근 권한이 없습니다.',
        404 => '정보를 찾을 수 없습니다.',
        409 => '이미 존재하는 정보입니다.',
        429 => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
        500 => '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
        _ => '오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
      };
    }
    return '오류가 발생했습니다.';
  }
}