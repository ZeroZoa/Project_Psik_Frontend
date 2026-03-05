import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../common/theme/app_colors.dart';
import '../../data/models/product_model.dart';

class ProductListItem extends StatelessWidget {
  final ProductModel product;
  final Color themeColor;
  final Color themeBgColor;

  const ProductListItem({
    super.key,
    required this.product,
    required this.themeColor,
    required this.themeBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,###", "ko_KR");

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // 1. 이미지 영역 (Safe Loading)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: themeBgColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias, // 이미지가 둥근 모서리를 넘지 않도록
            child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                ? Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              // [중요] 이미지 로딩 에러 처리
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.broken_image_outlined, color: themeColor);
              },
              // [선택] 로딩 중 표시
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                    color: themeColor,
                    strokeWidth: 2,
                  ),
                );
              },
            )
                : Icon(Icons.shopping_bag_outlined, color: themeColor),
          ),
          const SizedBox(width: 16),

          // 2. 텍스트 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.brand != null)
                  Text(
                    product.brand!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.description != null && product.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                if (product.price != null)
                  Text(
                    '${currencyFormat.format(product.price)}원',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}