import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/main_bottom_nav_bar.dart';
import '../../../../common/widgets/main_top_nav_bar.dart';
import '../../data/repositories/cosmetics_repository.dart';
import '../providers/home_provider.dart';

import '../widgets/ingredient_info_card.dart';
import '../widgets/product_list_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CosmeticsRepository>();

    return ChangeNotifierProvider(
      create: (_) => HomeProvider(repository)..init(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  // [UI Helper] 성분 타입(typeTitle)에 따른 테마 색상 결정 (HomeScreen용)
  ({Color color, Color bgColor}) _getThemeColors(String typeTitle) {
    switch (typeTitle) {
      case '일반/화장품':
        return (color: const Color(0xFF36BC9B), bgColor: const Color(0xFFDCFCE7)); // Green
      case '일반의약품/약국':
        return (color: const Color(0xFF3498DB), bgColor: const Color(0xFFDBEAFE)); // Blue
      case '전문의약품/병원':
        return (color: const Color(0xFFE74C3C), bgColor: const Color(0xFFFEE2E2)); // Red
      case '해외직구/직수입':
        return (color: const Color(0xFF34495E), bgColor: const Color(0xFFF3F4F6)); // Gray
      default:
        return (color: const Color(0xFF8E44AD), bgColor: const Color(0xFFF3E8FF)); // Default Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    if (provider.isListLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (provider.summaryList.isEmpty) {
      return Scaffold(
        backgroundColor: Color(0xFFFAFAF8),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("성분 정보를 불러올 수 없습니다."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.init(),
                child: const Text("다시 시도"),
              )
            ],
          ),
        ),
      );
    }

    // 현재 선택된 상세 정보
    final detail = provider.selectedDetail;

    // [중요] 상세 정보가 있으면 상세 정보의 타입을, 없으면 첫 번째 리스트의 타입을 사용 (로딩 중 등 방어 코드)
    final currentTypeTitle = detail?.typeTitle ?? provider.summaryList.first.typeTitle;

    final theme = _getThemeColors(currentTypeTitle);
    final themeColor = theme.color;
    final themeBgColor = theme.bgColor;

    // 하단 네비게이션용 고정 인덱스 (0: 홈)
    const int bottomNavIndex = 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async => await provider.init(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 0, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('당신에게 딱맞는 피부 공식', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('검증된 성분으로 피부 고민을 해결하세요.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    const SizedBox(height: 20),

                    // 성분 선택 탭
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.summaryList.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = provider.summaryList[index];
                          final isSelected = provider.selectedId == item.id;

                          // [탭 색상] 각 성분의 typeTitle에 맞춰 색상 결정
                          final itemTheme = _getThemeColors(item.typeTitle);
                          final itemColor = itemTheme.color;

                          return GestureDetector(
                            onTap: () => provider.selectIngredient(item.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? itemColor : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 상세 정보 카드 (색상 파라미터 제거됨 -> detail만 전달)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: provider.isDetailLoading
                    ? SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator(color: themeColor)),
                )
                    : (detail != null)
                    ? IngredientInfoCard(
                  detail: detail,
                  // [수정] 색상은 Card 내부에서 detail.typeTitle로 결정하므로 전달 안 함
                )
                    : const SizedBox.shrink(),
              ),
            ),

            // 제품 리스트 헤더
            if (!provider.isDetailLoading && detail != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                  child: Text(
                    '${detail.name} 추천 아이템',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            // 제품 리스트 (여전히 외부에서 색상 주입 필요 - 제품 모델엔 typeTitle이 없으므로)
            if (!provider.isDetailLoading && detail != null)
              detail.products.isEmpty
                  ? SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text("추천 제품이 아직 등록되지 않았어요.", style: TextStyle(color: Colors.grey)),
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final product = detail.products[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProductListItem(
                          product: product,
                          themeColor: themeColor,
                          themeBgColor: themeBgColor,
                        ),
                      );
                    },
                    childCount: detail.products.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}