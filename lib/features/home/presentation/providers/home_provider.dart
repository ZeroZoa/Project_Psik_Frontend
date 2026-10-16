import 'package:flutter/material.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../../features/auth/domain/enums/skin_concern.dart';
import '../../data/models/ingredient_detail_model.dart';
import '../../data/repositories/cosmetics_repository.dart';

class HomeProvider extends ChangeNotifier {
  final CosmeticsRepository _repository;
  List<SkinConcern> userSkinConcerns;

  HomeProvider(this._repository, {required this.userSkinConcerns});

  bool isLoading = true;
  String? errorMessage;

  // 고민별 추천 성분 상세 목록
  Map<SkinConcern, List<IngredientDetailModel>> recommendedDetailMap = {};

  // Psik 추천 기타 성분 상세 목록 (페이지 단위로 이어 붙임)
  List<IngredientDetailModel> otherIngredientDetails = [];
  bool hasMoreIngredients = false;
  bool isLoadingMore = false;
  int _ingredientPage = 0;

  Future<void> init({List<SkinConcern>? updatedConcerns}) async {
    if (updatedConcerns != null) {
      userSkinConcerns = updatedConcerns;
    }

    isLoading = true;
    notifyListeners();

    try {
      _ingredientPage = 0;
      if (userSkinConcerns.isNotEmpty) {
        final concerns = userSkinConcerns.map((e) => e.name).toList();

        // 추천 성분 + 전체 성분(첫 페이지) 병렬 조회
        final results = await Future.wait([
          _repository.getRecommendedIngredients(concerns),
          _repository.getIngredientsPage(),
        ]);

        final recommendedResult =
        results[0] as Map<String, List<IngredientDetailModel>>;
        final firstPage = results[1] as IngredientPage;

        recommendedDetailMap = {};
        for (final concern in userSkinConcerns) {
          recommendedDetailMap[concern] = recommendedResult[concern.name] ?? [];
        }

        otherIngredientDetails = firstPage.items;
        hasMoreIngredients = firstPage.hasMore;
      } else {
        final firstPage = await _repository.getIngredientsPage();
        otherIngredientDetails = firstPage.items;
        hasMoreIngredients = firstPage.hasMore;
      }
    } catch (e) {
      errorMessage = ApiErrorHandler.getMessage(e);
      debugPrint('[HomeProvider] 로드 실패: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 다음 페이지 성분을 이어서 불러온다 (스크롤이 끝에 가까워졌을 때 호출)
  Future<void> loadMoreIngredients() async {
    if (!hasMoreIngredients || isLoadingMore || isLoading) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = await _repository.getIngredientsPage(page: _ingredientPage + 1);
      otherIngredientDetails = [...otherIngredientDetails, ...nextPage.items];
      hasMoreIngredients = nextPage.hasMore;
      _ingredientPage++;
    } catch (e) {
      errorMessage = ApiErrorHandler.getMessage(e);
      debugPrint('[HomeProvider] 성분 추가 로드 실패: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }
}