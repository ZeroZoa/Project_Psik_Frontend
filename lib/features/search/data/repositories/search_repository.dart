import 'package:dio/dio.dart';
import '../../../home/data/models/ingredient_summary_model.dart';
import '../../../community/data/models/post_model.dart';

class SearchRepository {
  final Dio _dio;

  SearchRepository(this._dio);

  /// 성분 검색 (키워드 + 피부고민 필터)
  Future<List<IngredientSummaryModel>> searchIngredients({
    String? keyword,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/ingredients',
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          'page': page,
          'size': size,
        },
      );
      final List<dynamic> content = response.data['content'];
      return content.map((json) => IngredientSummaryModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('성분 검색 실패: $e');
    }
  }

  /// 게시글 검색 (키워드)
  Future<List<PostModel>> searchPosts(String keyword, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/posts/search',
        queryParameters: {'keyword': keyword, 'page': page, 'size': size},
      );
      final List<dynamic> content = response.data['content'];
      return content.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('게시글 검색 실패: $e');
    }
  }
}