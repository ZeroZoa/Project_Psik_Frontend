import 'package:dio/dio.dart';

import '../models/product_model.dart';

class MemberProductRepository {
  final Dio _dio;

  MemberProductRepository(this._dio);

  /// 샀어요 여부 + 수 조회
  Future<({bool owned, int count})> getOwnedStatus(int productId) async {
    try {
      final response = await _dio.get('/api/products/$productId/own');
      return (
      owned: response.data['owned'] as bool,
      count: response.data['count'] as int,
      );
    } catch (e) {
      throw Exception('샀어요 상태 조회 실패: $e');
    }
  }

  /// 샀어요 등록
  Future<({bool owned, int count})> markAsOwned(int productId) async {
    try {
      final response = await _dio.post('/api/products/$productId/own');
      return (
      owned: response.data['owned'] as bool,
      count: response.data['count'] as int,
      );
    } on DioException {
      rethrow;
    }
  }

  /// 내가 샀어요 누른 제품 목록
  Future<List<ProductModel>> getMyOwnedProducts() async {
    try {
      final response = await _dio.get('/api/products/me/owned');
      return (response.data as List<dynamic>)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('샀어요 목록 조회 실패: $e');
    }
  }

  /// 제품 이름/브랜드 검색 - GET /api/products/search
  /// [keyword] null 또는 빈 문자열이면 전체 조회
  Future<List<ProductModel>> searchProducts({String? keyword, int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get(
        '/api/products/search',
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          'page': page,
          'size': size,
        },
      );
      final List<dynamic> content = response.data['content'] as List<dynamic>;
      return content
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('제품 검색 실패: $e');
    }
  }
}