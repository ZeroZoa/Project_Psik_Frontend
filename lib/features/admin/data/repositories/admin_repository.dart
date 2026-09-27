import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
  }

  Future<void> deleteIngredient(int id) async {
    await _dio.delete('/api/admin/ingredients/$id');
  }

  Future<void> linkProduct(int ingredientId, int productId) async {
    await _dio.post(
        '/api/admin/ingredients/$ingredientId/products/$productId');
  }

  Future<void> unlinkProduct(int ingredientId, int productId) async {
    await _dio.delete(
        '/api/admin/ingredients/$ingredientId/products/$productId');
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
  }

  /// 제품 수정 — brand/price/description/link/imageUrl은 요청에 준 값 그대로
  /// 전체 교체된다 (부분 수정 아님). null을 넘기면 해당 필드가 null로 지워지므로,
  /// 호출부(ProductFormScreen)는 항상 폼의 전체 상태를 채워서 넘겨야 한다.
  Future<ProductModel> updateProduct({
    required int id,
    required String name,
    String? brand,
    int? price,
    String? description,
    String? link,
    String? imageUrl,
  }) async {
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
  }

  Future<void> deleteProduct(int id) async {
    await _dio.delete('/api/admin/products/$id');
  }

  Future<List<ProductModel>> getAllProducts() async {
    final response = await _dio.get('/api/admin/products');
    final List<dynamic> data = jsonDecode(jsonEncode(response.data['content']));
    return data
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 제품 이미지 업로드 → GCS URL 반환
  Future<String> uploadProductImage(XFile imageFile) async {
    MultipartFile multipartFile;

    if (kIsWeb) {
      final Uint8List bytes = await imageFile.readAsBytes();
      multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: imageFile.name,
      );
    } else {
      multipartFile = await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.name,
      );
    }

    final formData = FormData.fromMap({'image': multipartFile});

    final response = await _dio.post(
      '/api/admin/products/image',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response.data['imageUrl'];
  }
}
