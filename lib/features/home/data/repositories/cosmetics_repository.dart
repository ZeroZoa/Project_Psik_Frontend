import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/ingredient_detail_model.dart';
import '../models/product_model.dart';

class CosmeticsRepository {
  final Dio _dio;

  CosmeticsRepository(this._dio);

  Future<List<IngredientDetailModel>> getIngredients() async {
    try {
      final response = await _dio.get('/api/ingredients');
      final data = jsonDecode(jsonEncode(response.data));
      final List<dynamic> content = data['content'];
      return content.map((json) => IngredientDetailModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('성분 목록 조회 실패: $e');
    }
  }

  Future<IngredientDetailModel> getIngredientDetail(int id) async {
    try {
      final response = await _dio.get('/api/ingredients/$id');
      final data = jsonDecode(jsonEncode(response.data));
      return IngredientDetailModel.fromJson(data);
    } catch (e) {
      throw Exception('성분 상세 조회 실패: $e');
    }
  }

  Future<ProductModel> getProductById(int id) async {
    try {
      final response = await _dio.get('/api/products/$id');
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('제품 조회 실패: $e');
    }
  }

  Future<Map<String, List<IngredientDetailModel>>> getRecommendedIngredients(
      List<String> skinConcerns) async {
    try {
      final response = await _dio.get(
        '/api/ingredients/recommended',
        queryParameters: {'skinConcerns': skinConcerns},
      );

      // Flutter Web JSArray/JSObject → Dart List/Map 변환
      final List<dynamic> data = jsonDecode(jsonEncode(response.data));

      return Map.fromEntries(
        data.map((group) {
          final key = group['concern'] as String;
          final list = (group['ingredients'] as List<dynamic>)
              .map((e) => IngredientDetailModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return MapEntry(key, list);
        }),
      );
    } catch (e) {
      throw Exception('추천 성분 조회 실패: $e');
    }
  }
}