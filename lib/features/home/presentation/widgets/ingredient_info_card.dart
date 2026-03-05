import 'package:flutter/material.dart';
import '../../../../common/theme/app_colors.dart';
import '../../data/models/ingredient_detail_model.dart';

class IngredientInfoCard extends StatelessWidget {
  final IngredientDetailModel detail;

  const IngredientInfoCard({
    super.key,
    required this.detail,
  });

  // [UI Helper] 성분 타입에 따른 색상 반환
  ({Color color, Color bgColor}) _getThemeColors(String typeTitle) {
    switch (typeTitle) {
      case '일반/화장품': // GENERAL
        return (color: const Color(0xFF36BC9B), bgColor: const Color(0xFFDCFCE7)); // Green
      case '일반의약품/약국': // OTC
        return (color: const Color(0xFF3498DB), bgColor: const Color(0xFFDBEAFE)); // Blue
      case '전문의약품/병원': // PRESCRIPTION
        return (color: const Color(0xFFE74C3C), bgColor: const Color(0xFFFEE2E2)); // Red
      case '해외직구/직수입': // OVERSEAS
        return (color: const Color(0xFF34495E), bgColor: const Color(0xFFF3F4F6)); // Gray
      default:
        return (color: const Color(0xFF8E44AD), bgColor: const Color(0xFFF3E8FF)); // Default Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeColors(detail.typeTitle);
    final themeColor = theme.color;
    final themeBgColor = theme.bgColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeBgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeBgColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.science_outlined, color: themeColor),
                  const SizedBox(width: 8),
                  Text(
                    detail.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detail.typeTitle,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: themeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (detail.effects.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: detail.effects.take(4).map((effect) =>
                  Text("• $effect", style: TextStyle(color: themeColor, fontWeight: FontWeight.w600, fontSize: 13))
              ).toList(),
            ),
          const SizedBox(height: 16),
          Text(detail.description, style: TextStyle(color: Colors.black.withValues(alpha: 0.7), height: 1.5, fontSize: 14)),
          if (detail.cautions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text("⚠️ 주의사항", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error)),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: detail.cautions.map((caution) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text("- $caution", style: const TextStyle(fontSize: 12, color: AppColors.textBody)),
              )).toList(),
            )
          ]
        ],
      ),
    );
  }
}