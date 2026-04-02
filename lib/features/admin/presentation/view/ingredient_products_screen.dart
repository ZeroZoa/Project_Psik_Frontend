import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../home/data/models/ingredient_detail_model.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/data/repositories/cosmetics_repository.dart';
import '../providers/admin_provider.dart';

class IngredientProductsScreen extends StatefulWidget {
  final int ingredientId;
  final String ingredientName;

  const IngredientProductsScreen({
    super.key,
    required this.ingredientId,
    required this.ingredientName,
  });

  @override
  State<IngredientProductsScreen> createState() =>
      _IngredientProductsScreenState();
}

class _IngredientProductsScreenState
    extends State<IngredientProductsScreen> {
  IngredientDetailModel? _detail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final cosmeticsRepo = context.read<CosmeticsRepository>();
      final adminProvider = context.read<AdminProvider>();

      final detail =
      await cosmeticsRepo.getIngredientDetail(widget.ingredientId);
      await adminProvider.loadAllProducts();

      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로드 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _link(ProductModel product) async {
    final provider = context.read<AdminProvider>();
    try {
      await provider.linkProductToIngredient(
          widget.ingredientId, product.id);
      await _load();
      if (!mounted) return;
      _showSnack('${product.name} 연결되었습니다.', AppColors.success);
    } catch (e) {
      _showSnack('연결 실패: $e', AppColors.error);
    }
  }

  Future<void> _unlink(ProductModel product) async {
    final provider = context.read<AdminProvider>();
    try {
      await provider.unlinkProductFromIngredient(
          widget.ingredientId, product.id);
      await _load();
      if (!mounted) return;
      _showSnack('${product.name} 연결 해제되었습니다.', AppColors.success);
    } catch (e) {
      _showSnack('연결 해제 실패: $e', AppColors.error);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final linkedProducts = _detail?.products ?? [];
    final linkedIds = linkedProducts.map((p) => p.id).toSet();
    final allProducts = adminProvider.products;
    final unlinkableProducts =
    allProducts.where((p) => !linkedIds.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${widget.ingredientName} · 제품 관리',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textTitle,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── 연결된 제품 ──
            _SectionHeader(
              title: '연결된 제품',
              count: linkedProducts.length,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            if (linkedProducts.isEmpty)
              const _EmptyState(message: '연결된 제품이 없습니다.')
            else
              ...linkedProducts.map((p) => _ProductRow(
                product: p,
                actionLabel: '해제',
                actionColor: AppColors.error,
                onAction: () => _unlink(p),
              )),
            const SizedBox(height: 24),

            // ── 연결 가능한 제품 ──
            _SectionHeader(
              title: '연결 가능한 제품',
              count: unlinkableProducts.length,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 8),
            if (unlinkableProducts.isEmpty)
              const _EmptyState(message: '연결 가능한 제품이 없습니다.')
            else
              ...unlinkableProducts.map((p) => _ProductRow(
                product: p,
                actionLabel: '연결',
                actionColor: AppColors.primary,
                onAction: () => _link(p),
              )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── 섹션 헤더 ──
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.textTitle,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 빈 상태 ──
class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
              color: AppColors.textSub2, fontSize: 13),
        ),
      ),
    );
  }
}

// ── 제품 행 ──
class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onAction;

  const _ProductRow({
    required this.product,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              color: AppColors.surface,
              child: (product.imageUrl != null &&
                  product.imageUrl!.isNotEmpty)
                  ? Image.network(
                product.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.textSub1,
                    size: 20),
              )
                  : const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.textSub1, size: 20),
            ),
          ),
          const SizedBox(width: 12),

          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.brand != null && product.brand!.isNotEmpty)
                  Text(
                    product.brand!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSub2),
                  ),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textTitle,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 액션 버튼
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: actionColor,
              side: BorderSide(color: actionColor),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 16),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              actionLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: actionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}