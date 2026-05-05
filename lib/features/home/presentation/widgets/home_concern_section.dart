import 'package:flutter/material.dart';

import '../../../../../common/theme/app_colors.dart';
import '../../../auth/domain/enums/skin_concern.dart';
import '../../../home/data/models/ingredient_detail_model.dart';
import '../widgets/ingredient_info_card.dart';

/// 피부 고민별 맞춤 성분 섹션 위젯
/// - [concern] 피부 고민 enum — 섹션 타이틀로 표시
/// - [details] 해당 고민에 대한 성분 상세 목록 — 비어있으면 안내 문구 표시
/// - [isFirst] true면 상단 Divider 생략 (첫 번째 섹션)
/// - [_HomeView] SliverList 아이템으로 사용
class HomeConcernSection extends StatelessWidget {
  final SkinConcern concern;
  final List<IngredientDetailModel> details;
  final bool isFirst;

  const HomeConcernSection({
    super.key,
    required this.concern,
    required this.details,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 첫 번째 섹션이 아닐 때만 구분선 표시
        if (!isFirst)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Container(
                      width: 3.5,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      concern.displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textTitle,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '맞춤 성분',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSub2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSub2,
                size: 20,
              ),
              const SizedBox(width: 2),
            ],
          ),
        ),
        // 성분 목록 — 비어있으면 안내 문구
        if (details.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  '추천 성분이 없습니다.',
                  style: TextStyle(color: AppColors.textSub2),
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(42, 0, 42, 12),
            itemCount: details.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return IngredientInfoCard(detail: details[index]);
            },
          ),
      ],
    );
  }
}