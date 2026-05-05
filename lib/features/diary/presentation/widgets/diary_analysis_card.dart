import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../common/theme/app_colors.dart';
import '../providers/skin_analysis_provider.dart';

/// AI 피부 분석 결과 카드 위젯
/// - [SkinAnalysisProvider]를 직접 watch — analysis가 null이면 빈 위젯 반환
/// - PENDING / COMPLETED / FAILED 상태별 UI 분기
/// - [SkinDiaryScreen] 기록 카드 하단에 표시
class DiaryAnalysisCard extends StatelessWidget {
  const DiaryAnalysisCard({super.key});

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<SkinAnalysisProvider>().analysis;
    if (analysis == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.face_retouching_natural,
                  color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'AI 피부 분석 결과',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 분석 이미지 — 원본 비율 전체 표시
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              analysis.imageUrl,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppColors.surface,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // FAILED 상태
          if (analysis.isFailed)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '분석에 실패했습니다. 얼굴이 잘 보이는 사진을 사용해주세요.',
                      style: TextStyle(fontSize: 13, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            )

          // COMPLETED 상태
          else if (analysis.isCompleted) ...[
            if (analysis.summary != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  analysis.summary!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _DiaryAnalysisItem(
              label: '여드름 점수',
              value: '${analysis.acneScore ?? 0}점',
              score: analysis.acneScore ?? 0,
              color: AppColors.error,
            ),
            _DiaryAnalysisItem(
              label: '주름 점수',
              value: '${analysis.wrinkleScore ?? 0}점',
              score: analysis.wrinkleScore ?? 0,
              color: Colors.orange,
            ),
            _DiaryAnalysisItem(
              label: '피부결 점수',
              value: '${analysis.toneScore ?? 0}점',
              score: analysis.toneScore ?? 0,
              color: Colors.purple,
            ),
            _DiaryAnalysisItem(
              label: '유수분 점수',
              value: '${analysis.oilScore ?? 0}점',
              score: analysis.oilScore ?? 0,
              color: Colors.blue,
            ),
          ]

          // PENDING 상태
          else
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 12),
                  Text('분석 중입니다...',
                      style: TextStyle(color: AppColors.textSub2)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 분석 항목 한 줄 위젯 — 레이블 + 점수 + 프로그레스바
/// [DiaryAnalysisCard] 내부 전용
class _DiaryAnalysisItem extends StatelessWidget {
  final String label;
  final String value;
  final int score;
  final Color color;

  const _DiaryAnalysisItem({
    required this.label,
    required this.value,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody)),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}