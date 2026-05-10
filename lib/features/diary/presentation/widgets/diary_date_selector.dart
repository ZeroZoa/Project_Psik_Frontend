import 'package:flutter/material.dart';

import '../../../../../common/theme/app_colors.dart';

/// 주간 날짜 선택기 위젯
/// - 선택일 기준 앞뒤 3일씩 총 7일 표시
/// - 기록이 있는 날짜에 하단 인디케이터 표시 ([recordedDays] 기준)
/// - 오늘 날짜 하이라이트, 선택일 배경색 적용
/// - [SkinDiaryScreen] 상단 날짜 선택 영역에서 사용
class DiaryDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Set<int> recordedDays;
  final void Function(DateTime) onDateChanged;

  const DiaryDateSelector({
    super.key,
    required this.selectedDate,
    required this.recordedDays,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    const List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final DateTime now = DateTime.now();
    // 시간 성분 제거 — 날짜 기준으로만 비교하기 위해 정규화
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime selectedNormalized = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final DateTime startDay = selectedNormalized.subtract(const Duration(days: 3));
    final List<DateTime> displayDays =
    List.generate(7, (index) => startDay.add(Duration(days: index)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: displayDays.map((date) {
        final bool isSelected = date.year == selectedDate.year &&
            date.month == selectedDate.month &&
            date.day == selectedDate.day;
        final bool isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final bool hasRecord = recordedDays.contains(date.day) &&
            date.month == selectedDate.month &&
            date.year == selectedDate.year;
        final bool isAfterToday = date.isAfter(today);

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isAfterToday ? null : () => onDateChanged(date),
              borderRadius: BorderRadius.circular(14),
              hoverColor: isSelected
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.12),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      weekdays[date.weekday - 1],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAfterToday
                            ? Colors.grey.shade300
                            : isSelected
                            ? Colors.white
                            : (isToday ? AppColors.primary : AppColors.textSub2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAfterToday
                            ? Colors.grey.shade300
                            : isSelected
                            ? Colors.white
                            : AppColors.textTitle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: hasRecord ? 16 : 0,
                      height: 3,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}