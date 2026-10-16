import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/ingredient_detail_model.dart';
import '../models/product_model.dart';

/// 성분 목록 한 페이지 — hasMore: 다음 페이지가 더 있는지
typedef IngredientPage = ({List<IngredientDetailModel> items, bool hasMore});

class CosmeticsRepository {
  final Dio _dio;

  CosmeticsRepository(this._dio);

  Future<IngredientPage> getIngredientsPage({int page = 0, int size = 10}) async {
    final response = await _dio.get(
      '/api/ingredients',
      queryParameters: {'page': page, 'size': size},
    );
    final data = jsonDecode(jsonEncode(response.data));
    final List<dynamic> content = data['content'];
    final int totalPages = data['page']['totalPages'] as int;
    return (
      items: content
          .map((json) => IngredientDetailModel.fromJson(json as Map<String, dynamic>))
          .toList(),
      hasMore: page + 1 < totalPages,
    );
  }

  Future<IngredientDetailModel> getIngredientDetail(int id) async {
    final response = await _dio.get('/api/ingredients/$id');
    final data = jsonDecode(jsonEncode(response.data));
    return IngredientDetailModel.fromJson(data);
  }

  Future<ProductModel> getProductById(int id) async {
    final response = await _dio.get('/api/products/$id');
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, List<IngredientDetailModel>>> getRecommendedIngredients(
      List<String> skinConcerns) async {
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
  }
}
