import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../common/theme/app_colors.dart';
import '../../../diary/data/models/skin_diary_response.dart';

/// 최근 30일 피부 기록 그래프 섹션
/// - 피부점수 / 수면(h) / 수분(L) 3개 라인 차트
/// - [diaries] 비어있으면 "기록 없음" 안내 표시
/// - [MypageScreen] 프로필 헤더 하단에 표시
class MypageDiaryStatsSection extends StatelessWidget {
  final List<SkinDiaryResponse> diaries;

  const MypageDiaryStatsSection({super.key, required this.diaries});

  @override
  Widget build(BuildContext context) {
    final spots1 = <FlSpot>[]; // 피부점수
    final spots2 = <FlSpot>[]; // 수면시간
    final spots3 = <FlSpot>[]; // 물 섭취량
    final now = DateTime.now();

    for (final diary in diaries) {
      final daysAgo = now.difference(diary.recordDate).inDays.toDouble();
      final x = (30 - daysAgo).clamp(0.0, 30.0);
      spots1.add(FlSpot(x, diary.skinScore.toDouble()));
      spots2.add(FlSpot(x, (diary.sleepTimeMinutes ?? 0) / 60.0));
      spots3.add(FlSpot(x, (diary.waterIntakeMl ?? 0) / 1000.0));
    }

    for (final s in [spots1, spots2, spots3]) {
      s.sort((a, b) => a.x.compareTo(b.x));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 30일 피부 기록',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textTitle),
          ),
          const SizedBox(height: 8),

          // 범례
          Row(
            children: const [
              _Legend(color: AppColors.primary, label: '피부점수'),
              SizedBox(width: 12),
              _Legend(color: AppColors.textBody, label: '수면(h)'),
              SizedBox(width: 12),
              _Legend(color: Color(0xFF0EA5E9), label: '수분(L)'),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 160,
            child: diaries.isEmpty
                ? const Center(
                child: Text('기록 없음',
                    style: TextStyle(
                        color: AppColors.textSub2, fontSize: 13)))
                : LineChart(
              LineChartData(
                minX: 0, maxX: 30, minY: 0, maxY: 12,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 3,
                  getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFE5E7EB), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return const Text('30일 전',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSub2));
                        }
                        if (value == 30) {
                          return const Text('오늘',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSub2));
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _lineBar(spots: spots1, color: AppColors.primary),
                  _lineBar(spots: spots2, color: AppColors.textBody),
                  _lineBar(
                      spots: spots3,
                      color: const Color(0xFF0EA5E9)),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                    const Color(0xFFF3F4F6),
                    getTooltipItems: (touchedSpots) =>
                        touchedSpots.map((spot) {
                          final labels = ['점', '시간', 'L'];
                          final unit = labels[spot.barIndex];
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}$unit',
                            TextStyle(
                              color: spot.bar.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// LineChart 단일 라인 데이터 생성 헬퍼
  LineChartBarData _lineBar(
      {required List<FlSpot> spots, required Color color}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: spots.length <= 10,
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeColor: Colors.white,
          strokeWidth: 1.5,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}

/// 그래프 범례 위젯 — 컬러 바 + 레이블
/// [MypageDiaryStatsSection] 내부 전용
class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}