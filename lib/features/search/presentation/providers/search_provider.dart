import 'dart:async';

import 'package:flutter/material.dart';
import '../../../community/data/models/post_model.dart';
import '../../../home/data/models/ingredient_summary_model.dart';
import '../../data/repositories/search_repository.dart';

class SearchProvider extends ChangeNotifier {
  final SearchRepository _repository;

  SearchProvider(this._repository);

  static const _debounceDuration = Duration(milliseconds: 400);

  String keyword = '';
  bool isLoading = false;

  List<IngredientSummaryModel> ingredientResults = [];
  List<PostModel> postResults = [];

  Timer? _debounceTimer;
  // 가장 최근에 시작한 검색의 세대 번호. 네트워크 응답이 도착했을 때 이 값과
  // 다르면 그 사이 새 검색(또는 clear)이 시작된 것이므로 응답을 버린다 —
  // 느린 이전 검색 응답이 빠른 최신 검색 결과를 덮어쓰는 것을 방지.
  int _searchGeneration = 0;

  /// 검색창 입력 변화 시 호출 — 디바운스 후 검색 (매 글자마다 요청이 나가지 않도록)
  void onQueryChanged(String value) {
    keyword = value;
    _debounceTimer?.cancel();

    if (keyword.isEmpty) {
      _searchGeneration++; // 진행 중이던 응답도 전부 무효화
      ingredientResults = [];
      postResults = [];
      isLoading = false;
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () => _performSearch(keyword));
  }

  /// 검색 버튼/엔터 제출 — 디바운스 없이 즉시 검색
  Future<void> submitNow(String value) async {
    _debounceTimer?.cancel();
    keyword = value;
    await _performSearch(keyword);
  }

  Future<void> _performSearch(String searchKeyword) async {
    if (searchKeyword.isEmpty) return;

    final generation = ++_searchGeneration;
    isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.searchIngredients(keyword: searchKeyword),
        _repository.searchPosts(searchKeyword),
      ]);
      if (generation != _searchGeneration) return; // 늦게 도착한 응답 — 버림

      ingredientResults = results[0] as List<IngredientSummaryModel>;
      postResults = results[1] as List<PostModel>;
    } catch (e) {
      if (generation != _searchGeneration) return;
      debugPrint('[SearchProvider] 검색 실패: $e');
    } finally {
      if (generation == _searchGeneration) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void clear() {
    _debounceTimer?.cancel();
    _searchGeneration++;
    keyword = '';
    ingredientResults = [];
    postResults = [];
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
