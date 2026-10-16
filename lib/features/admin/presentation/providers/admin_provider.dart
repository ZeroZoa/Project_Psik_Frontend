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
  bool hasMoreProducts = false;
  bool isProductsLoadingMore = false;
  int _productPage = 0;
  // 성분에 제품을 연결할 때 고르는 전체 제품 목록 (제품 탭의 페이지 목록과 별개)
  List<ProductModel> selectableProducts = [];
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
      hasMoreIngredients = false; // 실패 시 같은 요청이 계속 반복되지 않도록 멈춘다 (당겨서 새로고침으로 재시도)
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
      // 페이지 단위로 불러오는 목록에서 한 건만 지우면 다음 페이지 경계가 어긋나므로 처음부터 다시 불러온다
      await loadIngredients();
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
      await _adminRepository.createProduct(
        name: name,
        brand: brand,
        price: price,
        description: description,
        link: link,
        imageUrl: imageUrl,
      );
      // 새 제품은 마지막 페이지에 들어가므로 첫 페이지부터 다시 불러온다
      await loadProducts();
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
      // 새 리스트로 교체해야 화면의 context.select가 변경을 감지한다 (제자리 수정 금지)
      products = [for (final p in products) p.id == id ? updated : p];
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
      await loadProducts(); // 페이지 경계가 어긋나지 않도록 처음부터 다시 불러온다
      return true;
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ── 제품 목록 로드 (제품 탭, 첫 페이지로 초기화) ──
  Future<void> loadProducts() async {
    isProductsLoading = true;
    error = null;
    notifyListeners();
    try {
      final firstPage = await _adminRepository.getProductsPage();
      products = firstPage.items;
      hasMoreProducts = firstPage.hasMore;
      _productPage = 0;
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
    } finally {
      isProductsLoading = false;
      notifyListeners();
    }
  }

  /// 다음 페이지 제품을 이어서 불러온다 (목록 끝 로딩 줄이 보일 때 호출)
  Future<void> loadMoreProducts() async {
    if (!hasMoreProducts || isProductsLoadingMore || isProductsLoading) return;

    isProductsLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = await _adminRepository.getProductsPage(page: _productPage + 1);
      // 새 리스트로 교체해야 화면의 context.select가 변경을 감지한다 (addAll로 제자리 수정 금지)
      products = [...products, ...nextPage.items];
      hasMoreProducts = nextPage.hasMore;
      _productPage++;
    } catch (e) {
      error = ApiErrorHandler.getMessage(e);
      hasMoreProducts = false; // 실패 시 같은 요청이 계속 반복되지 않도록 멈춘다
    } finally {
      isProductsLoadingMore = false;
      notifyListeners();
    }
  }

  // ── 연결용 전체 제품 목록 로드 (성분에 제품을 연결할 때 고르는 목록) ──
  // 연결 안 된 제품을 전부 보여줘야 해서 페이지네이션하지 않는다. 실패하면 호출한 화면이 처리한다.
  Future<void> loadSelectableProducts() async {
    selectableProducts = await _adminRepository.getAllProducts();
    notifyListeners();
  }
}