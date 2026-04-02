import 'package:dio/dio.dart';
import '../models/skin_diary_request.dart';
import '../models/skin_diary_response.dart';

class SkinDiaryRepository {
  final Dio _dio;

  SkinDiaryRepository(this._dio);

  /// 다이어리 작성 (POST /api/diaries)
  Future<SkinDiaryResponse> createDiary(SkinDiaryRequest request) async {
    try {
      final response = await _dio.post('/api/diaries', data: request.toJson());
      return SkinDiaryResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('다이어리 생성 실패: $e');
    }
  }

  /// 특정 일자 단건 조회 (GET /api/diaries/daily)
  Future<SkinDiaryResponse?> getDiaryByDate(DateTime date) async {
    try {
      final response = await _dio.get(
        '/api/diaries/daily',
        // 쿼리 파라미터로 UTC 시간 전송
        queryParameters: {'date': date.toUtc().toIso8601String()},
      );
      return SkinDiaryResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // 해당 날짜에 다이어리가 없는 경우 정상적인 null 반환
      }
      throw Exception('다이어리 조회 실패: $e');
    }
  }

  /// 다이어리 수정 (PUT /api/diaries/{diaryId})
  Future<SkinDiaryResponse> updateDiary(int diaryId, SkinDiaryRequest request) async {
    try {
      final response = await _dio.put('/api/diaries/$diaryId', data: request.toJson());
      return SkinDiaryResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('다이어리 수정 실패: $e');
    }
  }

  /// 다이어리 삭제 (DELETE /api/diaries/{diaryId})
  Future<void> deleteDiary(int diaryId) async {
    try {
      await _dio.delete('/api/diaries/$diaryId');
    } catch (e) {
      throw Exception('다이어리 삭제 실패: $e');
    }
  }

  /// 월별 다이어리 목록 조회 (GET /api/diaries/monthly)
  Future<List<SkinDiaryResponse>> getMonthlyDiaries(int year, int month) async {
    try {
      final response = await _dio.get(
        '/api/diaries/monthly',
        queryParameters: {'year': year, 'month': month},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => SkinDiaryResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('월별 다이어리 조회 실패: $e');
    }
  }

  /// 최근 30일 다이어리 목록 조회
  Future<List<SkinDiaryResponse>> getRecentDiaries() async {
    try {
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 30));
      final response = await _dio.get(
        '/api/diaries/range',
        queryParameters: {
          'from': from.toUtc().toIso8601String(),
          'to': now.toUtc().toIso8601String(),
        },
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => SkinDiaryResponse.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('최근 다이어리 조회 실패: $e');
    }
  }
}