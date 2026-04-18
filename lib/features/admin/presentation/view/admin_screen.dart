import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skinner_frontend/features/admin/presentation/view/product_form_screen.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../home/data/models/ingredient_summary_model.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/data/repositories/cosmetics_repository.dart';
import '../../data/repositories/admin_repository.dart';
import '../providers/admin_provider.dart';
import 'ingredient_form_screen.dart';
import 'ingredient_products_screen.dart';


/// 관리자 페이지 진입점
/// - AdminProvider를 생성하고 _AdminView에 주입
/// - [AdminScreen] → [_AdminView] → [_IngredientTab] / [_ProductTab]
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(
        context.read<AdminRepository>(),
        context.read<CosmeticsRepository>(),
      )..loadIngredients(),
      child: const _AdminView(),
    );
  }
}

/// 관리자 페이지 메인 뷰
/// - Scaffold + AppBar + TabBar 구성
/// - 탭 0: [_IngredientTab] (성분 관리)
/// - 탭 1: [_ProductTab] (제품 관리)
class _AdminView extends StatefulWidget {
  const _AdminView();

  @override
  State<_AdminView> createState() => _AdminViewState();
}

/// [_AdminView]의 State — TabController 생명주기 관리
class _AdminViewState extends State<_AdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  ///화면이 처음 열릴 때 딱 한 번 실행
  ///탭 2개짜리 컨트롤러를 생성해서 _tabController에 저장
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  ///위젯 트리를 제거할때, 직접 생성하 것들을 정리
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ///화면 build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textTitle, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '관리자페이지',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textTitle,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSub2,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: '성분 관리'),
            Tab(text: '제품 관리'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _IngredientTab(),
          _ProductTab(),
        ],
      ),
    );
  }
}

/// 성분 탭
/// [_AdminView] 탭 0 — 성분 목록 + 추가 FAB
/// - 목록 아이템: [_IngredientTile]
/// - 추가/수정: [IngredientFormScreen], 제품 연결: [IngredientProductsScreen]
class _IngredientTab extends StatelessWidget {
  const _IngredientTab();

  @override
  Widget build(BuildContext context) {
    ///Provider를 통해 화면에 뿌려질 데이터에 대한 상태와 로직 관리(Provider -> Repository를 call하여 로직 관리)
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<AdminProvider>(),
                child: const IngredientFormScreen(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: provider.isIngredientsLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : provider.ingredients.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('등록된 성분이 없습니다.',
                style: TextStyle(color: AppColors.textSub2)),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () => provider.loadIngredients(),
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: provider.ingredients.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _IngredientTile(
                ingredient: provider.ingredients[index]);
          },
        ),
      ),
    );
  }
}

/// [_IngredientTab] 리스트 아이템
/// - 성분명 + 타입 표시
/// - 액션: 제품 연결([IngredientProductsScreen]), 수정([IngredientFormScreen]), 삭제(확인 다이얼로그)
class _IngredientTile extends StatelessWidget {
  final IngredientSummaryModel ingredient;

  const _IngredientTile({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          ingredient.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textTitle,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            ingredient.typeTitle,
            style: const TextStyle(color: AppColors.textSub2, fontSize: 12),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            //제품 관리 버튼
            IconButton(
              icon: const Icon(Icons.link_rounded,
                  color: AppColors.secondary, size: 20),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: IngredientProductsScreen(
                        ingredientId: ingredient.id,
                        ingredientName: ingredient.name,
                      ),
                    ),
                  ),
                );
              },
            ),
            //수정 버튼
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 20),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: IngredientFormScreen(
                          ingredientId: ingredient.id),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              onPressed: () =>
                  _confirmDelete(context, provider, ingredient),
            ),
          ],
        ),
      ),
    );
  }

  ///성분 삭제 전 확인용 다이얼로그
  void _confirmDelete(BuildContext context, AdminProvider provider,
      IngredientSummaryModel ingredient) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('성분 삭제',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('${ingredient.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
              await provider.deleteIngredient(ingredient.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                Text(success ? '삭제되었습니다.' : '삭제에 실패했습니다.'),
                backgroundColor:
                success ? AppColors.success : AppColors.error,
              ));
            },
            child: const Text('삭제',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// 제품 탭
/// [_AdminView] 탭 1 — 제품 목록 + 추가 FAB
/// - 목록 아이템: [_ProductTile]
/// - 추가/수정: [ProductFormScreen]
class _ProductTab extends StatelessWidget {
  const _ProductTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<AdminProvider>(),
                child: const ProductFormScreen(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: provider.isProductsLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : provider.products.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('등록된 제품이 없습니다.',
                style: TextStyle(color: AppColors.textSub2)),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return _ProductTile(
              product: provider.products[index]);
        },
      ),
    );
  }
}

/// [_ProductTab] 리스트 아이템
/// - 제품명 + 브랜드 표시
/// - 액션: 수정([ProductFormScreen]), 삭제(확인 다이얼로그)
class _ProductTile extends StatelessWidget {
  final ProductModel product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textTitle,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            product.brand ?? '브랜드 없음',
            style:
            const TextStyle(color: AppColors.textSub2, fontSize: 12),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 20),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: ProductFormScreen(product: product),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 20),
              onPressed: () =>
                  _confirmDelete(context, provider, product),
            ),
          ],
        ),
      ),
    );
  }

  ///제품 삭제 전 확인용 다이얼로그
  void _confirmDelete(BuildContext context, AdminProvider provider,
      ProductModel product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('제품 삭제',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('${product.name}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
              await provider.deleteProduct(product.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                Text(success ? '삭제되었습니다.' : '삭제에 실패했습니다.'),
                backgroundColor:
                success ? AppColors.success : AppColors.error,
              ));
            },
            child: const Text('삭제',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}