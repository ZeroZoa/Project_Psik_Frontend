import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';


import '../../../../common/theme/app_colors.dart';
import '../../data/models/ingredient_detail_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/cosmetics_repository.dart';

/// 성분 타입별 색상 테마 타입 정의
/// [lightBg] 배경색, [textColor] 텍스트/뱃지 색, [gradient] 그라디언트 색상 리스트
typedef IngredientTheme = ({
Color lightBg,
Color textColor,
List<Color> gradient
});

/// 성분 상세 정보 화면 진입점
/// - [ingredientId]로 [CosmeticsRepository.getIngredientDetail] 호출
/// - 로딩 / 에러 / 정상 상태 분기 처리
class IngredientDetailScreen extends StatefulWidget {
  final int ingredientId;

  const IngredientDetailScreen({super.key, required this.ingredientId});

  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

/// [IngredientDetailScreen]의 State — 성분 상세 데이터 로드 및 상태 관리
/// 관리 상태: _detail(성분 상세), _isLoading, _error
class _IngredientDetailScreenState extends State<IngredientDetailScreen> {
  IngredientDetailModel? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 성분 상세 데이터 로드 — [CosmeticsRepository.getIngredientDetail] 호출
  /// 실패 시 _error 메시지 설정, RefreshIndicator의 onRefresh로도 재사용
  Future<void> _load() async {
    try {
      final repo = context.read<CosmeticsRepository>();
      final detail = await repo.getIngredientDetail(widget.ingredientId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '성분 정보를 불러올 수 없습니다.';
        _isLoading = false;
      });
    }
  }

  /// 성분 타입 표시명 → [IngredientTheme] 색상 테마 매핑
  /// - 일반/화장품: 그린, 일반의약품/약국: 블루
  /// - 전문의약품/병원: 레드, 기타(해외직구 등): 인디고
  IngredientTheme _getTheme(String typeTitle) {
    switch (typeTitle) {
      case '일반/화장품':
        return (
        lightBg: const Color(0xFFECFDF5),
        textColor: const Color(0xFF047857),
        gradient: const [Color(0xFF10B981), Color(0xFF2DD4BF)],
        );
      case '일반의약품/약국':
        return (
        lightBg: const Color(0xFFEFF6FF),
        textColor: const Color(0xFF1D4ED8),
        gradient: const [Color(0xFF3B82F6), Color(0xFF818CF8)],
        );
      case '전문의약품/병원':
        return (
        lightBg: const Color(0xFFFFF1F2),
        textColor: const Color(0xFFBE123C),
        gradient: const [Color(0xFFF43F5E), Color(0xFFF87171)],
        );
      default:
        return (
        lightBg: const Color(0xFFEEF2FF),
        textColor: const Color(0xFF4338CA),
        gradient: const [Color(0xFF6366F1), Color(0xFFA78BFA)],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null || _detail == null) return _buildError();

    final detail = _detail!;
    final theme = _getTheme(detail.typeTitle);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCard(detail: detail, theme: theme),
                    const SizedBox(height: 24),

                    if (detail.products.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 16),
                        child: Row(
                          children: [
                            SvgPicture.asset('assets/icons/shopping-bag.svg',
                                width: 20, height: 20,
                                colorFilter: const ColorFilter.mode(AppColors.textTitle, BlendMode.srcIn)),
                            const SizedBox(width: 5),
                            const Text(
                              '추천 아이템',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textTitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...detail.products.map(
                            (product) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ProductListCard(product: product),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (detail.cautions.isNotEmpty) ...[
                      _CautionsCard(cautions: detail.cautions),
                      const SizedBox(height: 20),
                    ],

                    if (detail.effects.isNotEmpty) ...[
                      _EffectsCard(effects: detail.effects, theme: theme),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 데이터 로드 중 표시하는 전체 화면 로딩 위젯
  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F7F9),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      ),
    );
  }

  /// 에러 발생 시 안내 + 재시도 버튼을 표시하는 전체 화면 위젯
  Widget _buildError() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textTitle, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '성분 정보',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textTitle,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.textSub2),
            const SizedBox(height: 16),
            Text(
              _error ?? '알 수 없는 오류가 발생했습니다.',
              style: const TextStyle(color: AppColors.textSub2),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () {
                setState(() => _isLoading = true);
                _load();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  /// 스크롤 시 고정되는 SliverAppBar — 뒤로가기 버튼 + "성분 정보" 타이틀
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
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
        '성분 정보',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textTitle,
        ),
      ),
    );
  }
}

/// 공통 카드 컨테이너 위젯 — 둥근 모서리 + 그림자
/// [color], [padding] 커스터마이징 가능
/// [_SummaryCard], [_EffectsCard], [_CautionsCard] 에서 재사용
class _BaseCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const _BaseCard({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// 성분 요약 카드 — 타입 뱃지 + 한/영 성분명 + 효과 요약 + 상세 설명
/// [theme]으로 타입별 색상 적용
class _SummaryCard extends StatelessWidget {
  final IngredientDetailModel detail;
  final IngredientTheme theme;



  const _SummaryCard({required this.detail, required this.theme});

  @override
  Widget build(BuildContext context) {
    return _BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타입 뱃지
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.lightBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              detail.typeTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 성분명
          Builder(
            builder: (context) {
              final parts = detail.name.split('/');
              final koreanName = parts[0].trim();
              final englishName = parts.length > 1 ? parts[1].trim() : null;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    koreanName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textTitle,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (englishName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      englishName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                        letterSpacing: 0.3,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // effectSummary
          if (detail.effectSummary.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double effectFontSize = 14;

                  final textPainter = TextPainter(
                    text: TextSpan(
                      text: detail.effectSummary,
                      style: const TextStyle(
                        fontSize: effectFontSize,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                        letterSpacing: 0.1,
                      ),
                    ),
                    maxLines: 2,
                    textDirection: ui.TextDirection.ltr,
                  )..layout(
                    maxWidth: constraints.maxWidth - 3 - 8 - 20,
                  );

                  final lineCount = textPainter.computeLineMetrics().length;
                  final barHeight = lineCount >= 2 ? 38.0 : 19.0;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 3,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          detail.effectSummary,
                          style: const TextStyle(
                            fontSize: effectFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textBody,
                            height: 1.5,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF3F4F6)),
          ),

          // 설명
          Text(
            detail.description,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

/// 핵심 효과 칩 가로 스크롤 카드
/// - 스크롤 위치에 따라 인디케이터 자동 업데이트 (StatefulWidget)
/// - 효과가 1개면 인디케이터 미표시
class _EffectsCard extends StatefulWidget {
  final List<String> effects;
  final IngredientTheme theme;

  const _EffectsCard({required this.effects, required this.theme});

  @override
  State<_EffectsCard> createState() => _EffectsCardState();
}

/// [_EffectsCard]의 State — ScrollController 생명주기 및 현재 인덱스 관리
class _EffectsCardState extends State<_EffectsCard> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      if (_currentIndex != 0) setState(() => _currentIndex = 0);
      return;
    }
    final current = (_scrollController.offset / maxScroll * (widget.effects.length - 1)).round();
    if (current != _currentIndex) {
      setState(() => _currentIndex = current.clamp(0, widget.effects.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 — 카드 밖
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              SvgPicture.asset('assets/icons/sparkle.svg',
                  width: 20, height: 20,
                  colorFilter: const ColorFilter.mode(AppColors.textTitle, BlendMode.srcIn)),
              const SizedBox(width: 8),
              const Text(
                '핵심 효과',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTitle,
                ),
              ),
            ],
          ),
        ),
        // 칩 목록 — 카드 안
        _BaseCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              SizedBox(
                height: 34,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.effects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.theme.lightBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: widget.theme.textColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.effects[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: widget.theme.textColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // ── 인디케이터 ──
              if (widget.effects.length > 1 && _scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.effects.length, (index) {
                    final isActive = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? widget.theme.textColor
                            : widget.theme.textColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 주의사항 카드 — 빨간 배경 + 불릿 포인트 목록
class _CautionsCard extends StatelessWidget {
  final List<String> cautions;

  const _CautionsCard({required this.cautions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 — 카드 밖
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              SvgPicture.asset('assets/icons/circle-alert.svg',
                  width: 20, height: 20,
                  colorFilter: const ColorFilter.mode(Color(0xFFE45D4B), BlendMode.srcIn)),
              SizedBox(width: 8),
              Text(
                '사용 시 주의해주세요',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE45D4B),
                ),
              ),
            ],
          ),
        ),
        // 카드 — 기존 컬러/스타일 유지
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              _BaseCard(
                color: const Color(0xFFFFE9E9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...cautions.map(
                      (caution) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '•',
                            style: TextStyle(
                              color: Color(0xFFF87171),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              caution,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF991B1B),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 추천 제품 리스트 아이템 카드 — 이미지 + 브랜드/이름/설명/가격 + 화살표
/// 탭 시 [ProductDetailScreen] (`/products/:id`)으로 이동
/// 마이페이지 제품 목록과 유사한 패턴 — 재사용 필요 시 공통 위젯으로 추출 가능
class _ProductListCard extends StatelessWidget {
  final ProductModel product;

  const _ProductListCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'ko_KR');

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}', extra: product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 이미지
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: (product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty)
                      ? Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  )
                      : SvgPicture.asset('assets/icons/shopping-bag.svg',
                      width: 40, height: 40,
                      colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
                ),
              ),
              const SizedBox(width: 16),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null && product.brand!.isNotEmpty)
                      Text(
                        product.brand!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSub2,
                          letterSpacing: 0.5,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textTitle,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSub2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (product.price != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${currencyFormat.format(product.price)}원',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textTitle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSub2,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}