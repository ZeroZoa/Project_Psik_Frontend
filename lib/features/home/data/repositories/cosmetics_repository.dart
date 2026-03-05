import 'package:dio/dio.dart';
import '../models/ingredient_summary_model.dart';
import '../models/ingredient_detail_model.dart';

class CosmeticsRepository {
  final Dio _dio;

  CosmeticsRepository(this._dio);

  // 성분 목록 조회 (GET /api/ingredients)
  // 백엔드 Page<IngredientResponse> 구조 처리를 위해 content 추출
  Future<List<IngredientSummaryModel>> getIngredients() async {
    try {
      final response = await _dio.get('/api/ingredients');

      // Spring Page 객체는 'content' 필드 안에 리스트가 있음
      final List<dynamic> content = response.data['content'];

      return content.map((json) => IngredientSummaryModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('성분 목록 조회 실패: $e');
    }
  }

  // 성분 상세 조회 (GET /api/ingredients/{id})
  Future<IngredientDetailModel> getIngredientDetail(int id) async {
    try {
      final response = await _dio.get('/api/ingredients/$id');
      return IngredientDetailModel.fromJson(response.data);
    } catch (e) {
      throw Exception('성분 상세 조회 실패: $e');
    }
  }
}