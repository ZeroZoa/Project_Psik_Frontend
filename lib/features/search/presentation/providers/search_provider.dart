import 'package:flutter/material.dart';
import '../../../community/data/models/post_model.dart';
import '../../../home/data/models/ingredient_summary_model.dart';
import '../../data/repositories/search_repository.dart';

class SearchProvider extends ChangeNotifier {
  final SearchRepository _repository;

  SearchProvider(this._repository);

  String keyword = '';
  bool isLoading = false;

  List<IngredientSummaryModel> ingredientResults = [];
  List<PostModel> postResults = [];

  Future<void> search({String? newKeyword}) async {
    if (newKeyword != null) keyword = newKeyword;

    if (keyword.isEmpty) {
      ingredientResults = [];
      postResults = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.searchIngredients(keyword: keyword),
        _repository.searchPosts(keyword),
      ]);
      ingredientResults = results[0] as List<IngredientSummaryModel>;
      postResults = results[1] as List<PostModel>;
    } catch (e) {
      debugPrint('[SearchProvider] 검색 실패: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    keyword = '';
    ingredientResults = [];
    postResults = [];
    notifyListeners();
  }
}