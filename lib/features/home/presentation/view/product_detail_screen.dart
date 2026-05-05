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

/// 제품 상세 정보 화면 진입점
/// - [product] GoRouter extra로 전달받은 [ProductModel]
/// - 샀어요 여부 및 카운트는 진입 시 [MemberProductRepository.getOwnedStatus]로 별도 조회
class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

/// [ProductDetailScreen]의 State — 샀어요 여부/카운트/로딩 상태 관리
/// 관리 상태: _owned(샀어요 여부), _ownedCount(총 샀어요 수), _isLoading
class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late bool _owned;
  late int _ownedCount;
  bool _isLoading = false;

  /// product.ownedCount로 초기값 설정 후 인증 사용자면 실제 샀어요 상태 조회
  @override
  void initState() {
    super.initState();
    _owned = false;
    _ownedCount = widget.product.ownedCount;
    _fetchOwnedStatus();
  }

  /// 샀어요 여부 + 총 카운트 조회 — [MemberProductRepository.getOwnedStatus] 호출
  /// 비로그인 시 조기 반환 (초기값 false/product.ownedCount 유지)
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

  /// RefreshIndicator의 onRefresh 핸들러 — 샀어요 상태 재조회
  Future<void> _refresh() async {
    await _fetchOwnedStatus();
  }

  /// 샀어요 등록 — [MemberProductRepository.markAsOwned] 호출
  /// - 비로그인 시 로그인 모달 표시
  /// - 이미 샀어요 등록했거나 로딩 중이면 조기 반환 (중복 방지)
  /// - 실패 시 서버 응답 메시지 스낵바 표시
  Future<void> _markAsOwned() async {
    final repo = context.read<MemberProductRepository>(); // ← await 전에 미리 캡처
    if (!await requireLogin(context)) return;
    if (_owned || _isLoading) return;

    setState(() => _isLoading = true);
    try {
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

            // ── 앱바 — 스크롤 시 pinned 고정 ──
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

                    // ── 제품 이미지 — 로딩/에러 상태 분기 ──
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

                    // ── 제품 설명 카드 (설명이 있는 경우에만 표시) ──
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

      // ── 하단 고정 bottomSheet — 샀어요 버튼 + 사러가기 버튼 ──
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
            // ── 샀어요 버튼 — 로딩/등록 상태에 따라 아이콘/카운트 변화 ──
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

            // ── 사러가기 버튼 — link 없으면 비활성화 ──
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