import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/login_modal.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/member_product_repository.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late bool _owned;
  late int _ownedCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _owned = false;
    _ownedCount = widget.product.ownedCount;
    _fetchOwnedStatus();
  }

  Future<void> _fetchOwnedStatus() async {
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    if (!isAuthenticated) return;

    try {
      final repo = context.read<MemberProductRepository>();
      final result = await repo.getOwnedStatus(widget.product.id);
      if (!mounted) return;
      setState(() {
        _owned = result.owned;
        _ownedCount = result.count;
      });
    } catch (_) {}
  }

  Future<void> _refresh() async {
    await _fetchOwnedStatus();
  }

  Future<void> _markAsOwned() async {
    if (!await requireLogin(context)) return;
    if (_owned || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final repo = context.read<MemberProductRepository>();
      final result = await repo.markAsOwned(widget.product.id);
      if (!mounted) return;
      setState(() {
        _owned = result.owned;
        _ownedCount = result.count;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data['message'] ?? '오류가 발생했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'ko_KR');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── 앱바 ──
            SliverAppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textTitle, size: 18),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                '제품 정보',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTitle,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── 이미지 ──
                    Container(
                      width: double.infinity,
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: (widget.product.imageUrl != null &&
                            widget.product.imageUrl!.isNotEmpty)
                            ? Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(LucideIcons.shoppingBag,
                                size: 64, color: AppColors.textSub1),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                    : null,
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                            : const Center(
                          child: Icon(LucideIcons.shoppingBag,
                              size: 64, color: AppColors.textSub1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── 브랜드 + 제품명 + 가격 카드 ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.product.brand != null &&
                              widget.product.brand!.isNotEmpty) ...[
                            Text(
                              widget.product.brand!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSub2,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textTitle,
                              height: 1.3,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (widget.product.price != null) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: Color(0xFFF3F4F6)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '판매가',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSub2,
                                  ),
                                ),
                                Text(
                                  '${currencyFormat.format(widget.product.price)}원',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textTitle,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 제품 설명 카드 ──
                    if (widget.product.description != null &&
                        widget.product.description!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(LucideIcons.info,
                                      size: 16, color: AppColors.primary),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  '제품 설명',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textTitle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.product.description!,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textBody,
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── 파트너스 안내 배너 ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.info,
                              size: 14, color: AppColors.textSub2),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '파트너스 링크를 통해 구매 시 소정의 수수료가 발생할 수 있어요.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSub2,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── 하단 고정 버튼 ──
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 샀어요 버튼 ──
            GestureDetector(
              onTap: _markAsOwned,
              child: SizedBox(
                width: 52,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isLoading
                          ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                          : Icon(
                        _owned
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey(_owned),
                        size: 28,
                        color: _owned
                            ? AppColors.error
                            : AppColors.textSub2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _ownedCount > 0 ? '$_ownedCount명' : '샀어요',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _owned ? AppColors.error : AppColors.textSub2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── 사러 가기 버튼 ──
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: (widget.product.link != null &&
                      widget.product.link!.isNotEmpty)
                      ? () async {
                    final uri = Uri.parse(widget.product.link!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.textSub1,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(LucideIcons.shoppingCart, size: 18),
                  label: const Text(
                    '사러 가기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}