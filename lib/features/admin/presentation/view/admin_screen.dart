import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:psik_frontend/features/admin/presentation/view/product_form_screen.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../home/data/models/ingredient_detail_model.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/data/repositories/cosmetics_repository.dart';
import '../../../mypage/data/models/InquiryModel.dart';
import '../../../mypage/data/repositories/inquiry_repository.dart';
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
      )..loadIngredients()..loadAllProducts(),
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
  ///탭 3개짜리 컨트롤러를 생성해서 _tabController에 저장
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: '문의 관리'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _IngredientTab(),
          _ProductTab(),
          _InquiryTab(),
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
  final IngredientDetailModel ingredient;
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
      IngredientDetailModel ingredient) {
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
/// 문의 관리 탭 (관리자)
/// - 전체 문의 목록 표시
/// - 아이템 탭 시 [_InquiryDetailScreen]으로 이동 (Navigator.push 패턴 동일)
class _InquiryTab extends StatefulWidget {
  const _InquiryTab();

  @override
  State<_InquiryTab> createState() => _InquiryTabState();
}

class _InquiryTabState extends State<_InquiryTab> {
  List<InquiryModel> _inquiries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  Future<void> _loadInquiries() async {
    setState(() => _isLoading = true);
    try {
      _inquiries =
      await context.read<InquiryRepository>().getAllInquiries();
    } catch (e) {
      debugPrint('문의 목록 조회 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_inquiries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('접수된 문의가 없습니다.',
                style: TextStyle(color: AppColors.textSub2)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInquiries,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _inquiries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final inquiry = _inquiries[index];
          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _InquiryDetailScreen(
                    inquiry: inquiry,
                    onAnswered: _loadInquiries,
                  ),
                ),
              );
            },
            child: Container(
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                title: Row(
                  children: [
                    // 상태 배지
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: inquiry.answered
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        inquiry.answered ? '답변 완료' : '미답변',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: inquiry.answered
                              ? AppColors.primary
                              : AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        inquiry.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textTitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Text(inquiry.authorNickname,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSub2)),
                      const Spacer(),
                      Text(_formatDate(inquiry.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSub2)),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSub2, size: 18),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}

/// 문의 상세 + 답변 화면 (관리자)
/// - Navigator.push 패턴 (_AdminView의 다른 서브화면과 동일)
/// - 답변 입력창: post_comment_input 패턴 (하단 고정)
/// - 답변 이미 있으면 입력창 미표시
class _InquiryDetailScreen extends StatefulWidget {
  final InquiryModel inquiry;
  final VoidCallback onAnswered;

  const _InquiryDetailScreen({
    required this.inquiry,
    required this.onAnswered,
  });

  @override
  State<_InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends State<_InquiryDetailScreen> {
  final _answerController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final content = _answerController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<InquiryRepository>().createAnswer(
        inquiryId: widget.inquiry.id,
        content: content,
      );
      if (!mounted) return;
      widget.onAnswered();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('답변이 등록되었습니다.'),
            backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('답변 등록에 실패했습니다.'),
            backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inquiry = widget.inquiry;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textTitle),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('문의 상세',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textTitle)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── 문의 내용 ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 + 날짜
                  Row(
                    children: [
                      Text(inquiry.authorNickname,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textBody)),
                      const Spacer(),
                      Text(_formatDate(inquiry.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSub2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 제목
                  Text(inquiry.title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTitle)),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  // 내용
                  Text(inquiry.content,
                      style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textBody,
                          height: 1.6)),
                  // 기존 답변 표시
                  if (inquiry.answered && inquiry.answerContent != null) ...[
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                            AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('답변',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ),
                        const Spacer(),
                        if (inquiry.answeredAt != null)
                          Text(_formatDate(inquiry.answeredAt!),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSub2)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(inquiry.answerContent!,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textBody,
                            height: 1.6)),
                  ],
                ],
              ),
            ),
          ),

          // ── 답변 입력창 (post_comment_input 패턴, 답변 없을 때만) ──
          if (!inquiry.answered)
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _answerController,
                      decoration: InputDecoration(
                        hintText: '답변을 입력하세요...',
                        hintStyle: const TextStyle(
                            fontSize: 14, color: AppColors.textSub1),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _submitAnswer,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}