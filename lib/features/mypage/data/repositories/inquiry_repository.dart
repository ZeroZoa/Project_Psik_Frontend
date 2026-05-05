import 'package:dio/dio.dart';
import '../models/InquiryModel.dart';

/// 문의하기 Repository
class InquiryRepository {
  final Dio _dio;
  InquiryRepository(this._dio);

  /// 문의 등록 (사용자)
  Future<InquiryModel> createInquiry({
    required String title,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '/api/inquiries',
        data: {'title': title, 'content': content},
      );
      return InquiryModel.fromJson(response.data);
    } catch (e) {
      throw Exception('문의 등록 실패: $e');
    }
  }

  /// 내 문의 목록 (사용자)
  Future<List<InquiryModel>> getMyInquiries({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/inquiries/mine',
        queryParameters: {'page': page, 'size': size},
      );
      final List<dynamic> content = response.data['content'];
      return content.map((e) => InquiryModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('문의 목록 조회 실패: $e');
    }
  }

  /// 전체 문의 목록 (관리자)
  Future<List<InquiryModel>> getAllInquiries({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/inquiries/admin',
        queryParameters: {'page': page, 'size': size},
      );
      final List<dynamic> content = response.data['content'];
      return content.map((e) => InquiryModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('전체 문의 목록 조회 실패: $e');
    }
  }

  /// 답변 등록 (관리자)
  Future<InquiryModel> createAnswer({
    required int inquiryId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '/api/inquiries/$inquiryId/answer',
        data: {'content': content},
      );
      return InquiryModel.fromJson(response.data);
    } catch (e) {
      throw Exception('답변 등록 실패: $e');
    }
  }
}