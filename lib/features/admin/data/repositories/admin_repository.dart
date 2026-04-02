import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../home/data/models/ingredient_detail_model.dart';
import '../../../home/data/models/product_model.dart';

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  // ── Ingredient ──

  Future<IngredientDetailModel> createIngredient({
    required String name,
    required String type,
    required String effectSummary,
    required String description,
    required List<String> effects,
    required List<String> cautions,
    required List<String> skinConcerns,
  }) async {
    try {
      final response = await _dio.post(
        '/api/admin/ingredients',
        data: {
          'name': name,
          'type': type,
          'effectSummary': effectSummary,
          'description': description,
          'effects': effects,
          'cautions': cautions,
          'skinConcerns': skinConcerns,
        },
      );
      return IngredientDetailModel.fromJson(
          jsonDecode(jsonEncode(response.data)));
    } catch (e) {
      throw Exception('성분 생성 실패: $e');
    }
  }

  Future<IngredientDetailModel> updateIngredient({
    required int id,
    required String name,
    required String type,
    required String effectSummary,
    required String description,
    required List<String> effects,
    required List<String> cautions,
    required List<String> skinConcerns,
  }) async {
    try {
      final response = await _dio.put(
        '/api/admin/ingredients/$id',
        data: {
          'name': name,
          'type': type,
          'effectSummary': effectSummary,
          'description': description,
          'effects': effects,
          'cautions': cautions,
          'skinConcerns': skinConcerns,
        },
      );
      return IngredientDetailModel.fromJson(
          jsonDecode(jsonEncode(response.data)));
    } catch (e) {
      throw Exception('성분 수정 실패: $e');
    }
  }

  Future<void> deleteIngredient(int id) async {
    try {
      await _dio.delete('/api/admin/ingredients/$id');
    } catch (e) {
      throw Exception('성분 삭제 실패: $e');
    }
  }

  Future<void> linkProduct(int ingredientId, int productId) async {
    try {
      await _dio.post(
          '/api/admin/ingredients/$ingredientId/products/$productId');
    } catch (e) {
      throw Exception('제품 연결 실패: $e');
    }
  }

  Future<void> unlinkProduct(int ingredientId, int productId) async {
    try {
      await _dio.delete(
          '/api/admin/ingredients/$ingredientId/products/$productId');
    } catch (e) {
      throw Exception('제품 연결 해제 실패: $e');
    }
  }

  // ── Product ──

  Future<ProductModel> createProduct({
    required String name,
    String? brand,
    int? price,
    String? description,
    String? link,
    String? imageUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/api/admin/products',
        data: {
          'name': name,
          if (brand != null) 'brand': brand,
          if (price != null) 'price': price,
          if (description != null) 'description': description,
          if (link != null) 'link': link,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
      return ProductModel.fromJson(jsonDecode(jsonEncode(response.data)));
    } catch (e) {
      throw Exception('제품 생성 실패: $e');
    }
  }

  Future<ProductModel> updateProduct({
    required int id,
    required String name,
    String? brand,
    int? price,
    String? description,
    String? link,
    String? imageUrl,
  }) async {
    try {
      final response = await _dio.put(
        '/api/admin/products/$id',
        data: {
          'name': name,
          'brand': brand,
          'price': price,
          'description': description,
          'link': link,
          'imageUrl': imageUrl,
        },
      );
      return ProductModel.fromJson(jsonDecode(jsonEncode(response.data)));
    } catch (e) {
      throw Exception('제품 수정 실패: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/api/admin/products/$id');
    } catch (e) {
      throw Exception('제품 삭제 실패: $e');
    }
  }

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await _dio.get('/api/admin/products');
      final List<dynamic> data = jsonDecode(jsonEncode(response.data));
      return data
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('전체 제품 목록 조회 실패: $e');
    }
  }


}