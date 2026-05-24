import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../common/theme/app_colors.dart';
import '../../data/models/ingredient_detail_model.dart';
import '../../data/models/product_model.dart';

class IngredientInfoCard extends StatelessWidget {
  final IngredientDetailModel detail;

  const IngredientInfoCard({super.key, required this.detail});



  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () => context.push('/ingredients/${detail.id}'),
      child: Container(
      padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.inputBorder.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── 성분명 ──
            Builder(
              builder: (context) {
                final parts = detail.name.split('/');
                final koreanName = parts[0].trim();
                final englishName = parts.length > 1 ? parts[1].trim() : null;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (englishName != null) ...[
                      Text(
                        koreanName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTitle,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        englishName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            // ── effectSummary ──
            if (detail.effectSummary.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3, bottom: 3),
                        width: 3,
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
                            fontSize: 13,
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
                  ),
                ),
              ),

            // ── effects ──
            if (detail.effects.isNotEmpty)
              SizedBox(
                height: 26,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: detail.effects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '#',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            detail.effects[index],
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textBody,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),


            // ── 디바이더 + 추천 제품 ──
            if (detail.products.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.inputBorder),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 14, color: AppColors.textTitle),
                  const SizedBox(width: 5),
                  const Text(
                    '추천 아이템',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 218,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: detail.products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _ProductCard(
                      product: detail.products[index],
                      themeColor: AppColors.primary,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final Color themeColor;

  const _ProductCard({required this.product, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'ko_KR');

    return SizedBox(
      width: 130,
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── 이미지 ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 130,
                    height: 130,
                    color: AppColors.surface,
                    child: (product.imageUrl != null &&
                        product.imageUrl!.isNotEmpty)
                        ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: AppColors.textSub1, size: 32),
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
                      child: Icon(Icons.shopping_bag_outlined,
                          color: AppColors.textSub1, size: 32),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── 브랜드 ──
            if (product.brand != null && product.brand!.isNotEmpty) ...[
              Text(
                product.brand!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSub2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
            ],

            // ── 제품명 ──
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textTitle,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // ── 가격 + 샀어요 수 ──
            if (product.price != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${currencyFormat.format(product.price)}원',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: themeColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    product.ownedCount > 0
                        ? '${product.ownedCount}명이 샀어요'
                        : '샀어요',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSub2,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}