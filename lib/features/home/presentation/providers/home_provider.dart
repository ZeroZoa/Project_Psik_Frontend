import 'package:flutter/material.dart';

import '../../data/models/ingredient_detail_model.dart';
import '../../data/models/ingredient_summary_model.dart';
import '../../data/repositories/cosmetics_repository.dart';


class HomeProvider extends ChangeNotifier {
  final CosmeticsRepository _repository;

  HomeProvider(this._repository);

  bool isListLoading = true;
  bool isDetailLoading = false;

  List<IngredientSummaryModel> summaryList = [];
  IngredientDetailModel? selectedDetail;
  int? selectedId;

  // 초기화: 목록 불러오기 -> 첫 번째 성분 상세 자동 로드
  Future<void> init() async {
    isListLoading = true;
    notifyListeners();

    try {
      summaryList = await _repository.getIngredients();
      if (summaryList.isNotEmpty) {
        await selectIngredient(summaryList.first.id);
      }
    } catch (e) {
      debugPrint("Error loading ingredients: $e");
    } finally {
      isListLoading = false;
      notifyListeners();
    }
  }

  // 성분 탭 선택 시 상세 정보 로드
  Future<void> selectIngredient(int id) async {
    // 이미 선택된 거면 무시 (불필요한 API 호출 방지)
    if (selectedId == id && selectedDetail != null) return;

    selectedId = id;
    isDetailLoading = true;
    notifyListeners(); // 로딩 UI 표시

    try {
      selectedDetail = await _repository.getIngredientDetail(id);
    } catch (e) {
      debugPrint("Error loading detail: $e");
      selectedDetail = null;
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }
}