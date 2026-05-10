import 'package:flutter/material.dart';
import '../../../../features/auth/domain/enums/skin_concern.dart';
import '../../data/models/ingredient_detail_model.dart';
import '../../data/repositories/cosmetics_repository.dart';

class HomeProvider extends ChangeNotifier {
  final CosmeticsRepository _repository;
  final List<SkinConcern> userSkinConcerns;

  HomeProvider(this._repository, {required this.userSkinConcerns});

  bool isLoading = true;

  // 고민별 추천 성분 상세 목록
  Map<SkinConcern, List<IngredientDetailModel>> recommendedDetailMap = {};

  // Psik 추천 기타 성분 상세 목록
  List<IngredientDetailModel> otherIngredientDetails = [];

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    try {
      if (userSkinConcerns.isNotEmpty) {
        // 로그인 + 고민 설정된 유저 → 추천 성분 로드
        final concerns = userSkinConcerns.map((e) => e.name).toList();
        final result = await _repository.getRecommendedIngredients(concerns);

        recommendedDetailMap = {};
        for (final concern in userSkinConcerns) {
          final summaries = result[concern.name] ?? [];
          final results = await Future.wait(
            summaries.map((s) async {
              try {
                return await _repository.getIngredientDetail(s.id);
              } catch (e) {
                debugPrint('[HomeProvider] 상세 로드 실패 (id=${s.id}): $e');
                return null;
              }
            }),
          );
          recommendedDetailMap[concern] =
              results.whereType<IngredientDetailModel>().toList();
        }

        // Psik 추천 성분 전체 노출 (로그인 유저도 전체 보여줌)
        final allSummaries = await _repository.getIngredients();
        final otherResults = await Future.wait(
          allSummaries.map((s) async {
            try {
              return await _repository.getIngredientDetail(s.id);
            } catch (e) {
              debugPrint('[HomeProvider] 기타 상세 로드 실패 (id=${s.id}): $e');
              return null;
            }
          }),
        );
        otherIngredientDetails =
            otherResults.whereType<IngredientDetailModel>().toList();
      } else {
        // 비로그인 or 고민 미설정 → 전체 성분 로드
        final allSummaries = await _repository.getIngredients();
        final otherResults = await Future.wait(
          allSummaries.map((s) async {
            try {
              return await _repository.getIngredientDetail(s.id);
            } catch (e) {
              debugPrint('[HomeProvider] 전체 성분 로드 실패 (id=${s.id}): $e');
              return null;
            }
          }),
        );
        otherIngredientDetails =
            otherResults.whereType<IngredientDetailModel>().toList();
      }
    } catch (e) {
      debugPrint('[HomeProvider] 로드 실패: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}