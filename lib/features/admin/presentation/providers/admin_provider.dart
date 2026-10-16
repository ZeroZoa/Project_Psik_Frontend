import 'package:flutter/material.dart';

import '../../../../core/network/api_error_handler.dart';
import '../../../home/data/models/ingredient_detail_model.dart';
import '../../../home/data/models/ingredient_summary_model.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/data/repositories/cosmetics_repository.dart';
import '../../data/repositories/admin_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _adminRepository;
  final CosmeticsRepository _cosmeticsRepository;

  AdminProvider(this._adminRepository, this._cosmeticsRepository);

  List<IngredientDetailModel> ingredients = [];
  List<ProductModel> products = [];
  bool isIngredientsLoading = false;
  bool hasMoreIngredients = false;
  bool isIngredientsLoadingMore = false;
  int _ingredientPage = 0;
  bool isProductsLoading = false;
  String? error;

  // ── 성분 목록 로드 (첫 페이지로 초기화) ──
  Future<void> loadIngredients() async {
    isIngredientsLoading = true;
    error = null;
    notifyListeners();
    try {
      final firstPage = await _cosmeticsRepository.getIngredientsPage();
      ingredients = firstPage.items;
      hasMoreIngredients = firstPage.hasMore;
      _ingredientPage = 0;
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
    } finally {
      isIngredientsLoading = false;
      notifyListeners();
    }
  }

  /// 다음 페이지 성분을 이어서 불러온다 (목록 끝에 가까워졌을 때 호출)
  Future<void> loadMoreIngredients() async {
    if (!hasMoreIngredients || isIngredientsLoadingMore || isIngredientsLoading) return;

    isIngredientsLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = await _cosmeticsRepository.getIngredientsPage(page: _ingredientPage + 1);
      // 새 리스트로 교체해야 화면의 context.select가 변경을 감지한다 (addAll로 제자리 수정 금지)
      ingredients = [...ingredients, ...nextPage.items];
      hasMoreIngredients = nextPage.hasMore;
      _ingredientPage++;
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
    } finally {
      isIngredientsLoadingMore = false;
      notifyListeners();
    }
  }

  // ── 성분 생성 ──
  Future<bool> createIngredient({
    required String name,
    required String type,
    required String effectSummary,
    required String description,
    required List<String> effects,
    required List<String> cautions,
    required List<String> skinConcerns,
  }) async {
    try {
      await _adminRepository.createIngredient(
        name: name,
        type: type,
        effectSummary: effectSummary,
        description: description,
        effects: effects,
        cautions: cautions,
        skinConcerns: skinConcerns,
      );
      await loadIngredients();
      return true;
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── 성분 수정 ──
  Future<bool> updateIngredient({
    required int id,
    required String name,
    required String type,
    required String effectSummary,
    required String description,
    required List<String> effects,
    required List<String> cautions,
    required List<String> skinConcerns,
  }) async {
    try {
      await _adminRepository.updateIngredient(
        id: id,
        name: name,
        type: type,
        effectSummary: effectSummary,
        description: description,
        effects: effects,
        cautions: cautions,
        skinConcerns: skinConcerns,
      );
      await loadIngredients();
      return true;
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> linkProductToIngredient(int ingredientId, int productId) async {
    await _adminRepository.linkProduct(ingredientId, productId);
  }

  Future<void> unlinkProductFromIngredient(int ingredientId, int productId) async {
    await _adminRepository.unlinkProduct(ingredientId, productId);
  }

  // ── 성분 삭제 ──
  Future<bool> deleteIngredient(int id) async {
    try {
      await _adminRepository.deleteIngredient(id);
      ingredients.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── 제품 생성 ──
  Future<bool> createProduct({
    required String name,
    String? brand,
    int? price,
    String? description,
    String? link,
    String? imageUrl,
  }) async {
    try {
      final product = await _adminRepository.createProduct(
        name: name,
        brand: brand,
        price: price,
        description: description,
        link: link,
        imageUrl: imageUrl,
      );
      products.add(product);
      notifyListeners();
      return true;
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── 제품 수정 ──
  Future<bool> updateProduct({
    required int id,
    required String name,
    String? brand,
    int? price,
    String? description,
    String? link,
    String? imageUrl,
  }) async {
    try {
      final updated = await _adminRepository.updateProduct(
        id: id,
        name: name,
        brand: brand,
        price: price,
        description: description,
        link: link,
        imageUrl: imageUrl,
      );
      final index = products.indexWhere((e) => e.id == id);
      if (index != -1) products[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── 제품 삭제 ──
  Future<bool> deleteProduct(int id) async {
    try {
      await _adminRepository.deleteProduct(id);
      products.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── 전체 제품 목록 로드 (성분 연결 시 선택용) ──
  Future<void> loadAllProducts() async {
    isProductsLoading = true;
    error = null;
    notifyListeners();
    try {
      products = await _adminRepository.getAllProducts();
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
    } finally {
      isProductsLoading = false;
      notifyListeners();
    }
  }
}