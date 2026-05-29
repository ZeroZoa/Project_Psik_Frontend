import 'package:flutter/material.dart';
import '../../../../features/auth/domain/enums/skin_concern.dart';
import '../../data/models/ingredient_detail_model.dart';
import '../../data/repositories/cosmetics_repository.dart';

class HomeProvider extends ChangeNotifier {
  final CosmeticsRepository _repository;
  List<SkinConcern> userSkinConcerns;

  HomeProvider(this._repository, {required this.userSkinConcerns});

  bool isLoading = true;

  // 고민별 추천 성분 상세 목록
  Map<SkinConcern, List<IngredientDetailModel>> recommendedDetailMap = {};

  // Psik 추천 기타 성분 상세 목록
  List<IngredientDetailModel> otherIngredientDetails = [];

  Future<void> init({List<SkinConcern>? updatedConcerns}) async {
    if (updatedConcerns != null) {
      userSkinConcerns = updatedConcerns;
    }

    isLoading = true;
    notifyListeners();

    try {
      if (userSkinConcerns.isNotEmpty) {
        final concerns = userSkinConcerns.map((e) => e.name).toList();

        // 추천 성분 + 전체 성분 병렬 조회
        final results = await Future.wait([
          _repository.getRecommendedIngredients(concerns),
          _repository.getIngredients(), // ← 상세 직접 반환
        ]);

        final recommendedResult =
        results[0] as Map<String, List<IngredientDetailModel>>;
        final allDetails = results[1] as List<IngredientDetailModel>;

        recommendedDetailMap = {};
        for (final concern in userSkinConcerns) {
          recommendedDetailMap[concern] = recommendedResult[concern.name] ?? [];
        }

        otherIngredientDetails = allDetails;
      } else {
        otherIngredientDetails = await _repository.getIngredients();
      }
    } catch (e) {
      debugPrint('[HomeProvider] 로드 실패: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}