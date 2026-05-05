import 'package:flutter/material.dart';

/// 다이어리 기록 폼 공통 슬라이더 위젯
/// - 아이콘 + 타이틀 + 현재 값 표시 + 슬라이더
/// - 외부 상태 의존 없는 순수 위젯 (값/콜백 파라미터로만 동작)
/// - [SkinDiaryScreen] 수면 시간, 물 섭취량 입력에서 재사용
class DiarySliderField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final double value;
  final String unit;
  final double min;
  final double max;
  final int divisions;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const DiarySliderField({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.divisions,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151), // AppColors.textBody
                  ),
                ),
              ],
            ),
            Text(
              '${value.toStringAsFixed(value == value.truncateToDouble() ? 0 : 1)}$unit',
              style: TextStyle(fontWeight: FontWeight.bold, color: activeColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: activeColor,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: Colors.white,
            overlayColor: activeColor.withValues(alpha: 0.2),
            thumbShape:
            const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 2),
            tickMarkShape: SliderTickMarkShape.noTickMark,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}