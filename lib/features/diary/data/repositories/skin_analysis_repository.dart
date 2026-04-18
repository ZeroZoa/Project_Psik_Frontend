import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../models/skin_analysis_response.dart';

// 피부 분석 API 레포지토리
class SkinAnalysisRepository {
  final Dio _dio;

  SkinAnalysisRepository(this._dio);

  /// 피부 분석 요청 (POST /api/diaries/{diaryId}/analysis)
  Future<SkinAnalysisResponse> analyze(int diaryId, XFile imageFile) async {
    try {
      MultipartFile multipartFile;

      if (kIsWeb) {
        // Web — 바이트로 읽어서 MultipartFile 생성
        final Uint8List bytes = await imageFile.readAsBytes();
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
        );
      } else {
        // Mobile/Desktop — 파일 경로로 생성
        multipartFile = await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.name,
        );
      }

      final formData = FormData.fromMap({'image': multipartFile});

      final response = await _dio.post(
        '/api/diaries/$diaryId/analysis',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return SkinAnalysisResponse.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? '피부 분석에 실패했습니다.';
      throw Exception(message);
    }
  }

  /// 피부 분석 결과 조회 (GET /api/diaries/{diaryId}/analysis)
  Future<SkinAnalysisResponse?> getAnalysis(int diaryId) async {
    try {
      final response = await _dio.get('/api/diaries/$diaryId/analysis');
      return SkinAnalysisResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('분석 결과 조회 실패: $e');
    }
  }
}