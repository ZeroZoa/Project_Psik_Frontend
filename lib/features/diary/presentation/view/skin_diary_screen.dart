import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../data/models/skin_diary_request.dart';
import '../providers/skin_diary_provider.dart';

class SkinDiaryScreen extends StatefulWidget {
  const SkinDiaryScreen({super.key});

  @override
  State<SkinDiaryScreen> createState() => _SkinDiaryScreenState();
}

class _SkinDiaryScreenState extends State<SkinDiaryScreen> {
  // [State] 날짜 선택 상태 (기본값: 오늘)
  DateTime _selectedDate = DateTime.now();

  // [#1] 디폴트값 전부 0으로 변경
  double _sleepHours = 0.0;
  double _waterLiters = 0.0;
  final TextEditingController _dietController = TextEditingController();
  final List<int> _selectedProductIds = [];
  int _skinScore = 0;

  // [#3] 날짜 전환 애니메이션 방향 추적
  // true = 오른쪽→왼쪽(미래로), false = 왼쪽→오른쪽(과거로)
  bool _slideForward = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 화면 진입 시 오늘 날짜의 다이어리 + 이번 달 기록 날짜 조회
      _loadDiaryForDate(_selectedDate);
      _loadMonthlyRecords(_selectedDate);
    });
  }

  @override
  void dispose() {
    _dietController.dispose();
    super.dispose();
  }

  /// [#5] 선택된 날짜가 속한 월의 기록 날짜들을 조회
  Future<void> _loadMonthlyRecords(DateTime date) async {
    final provider = context.read<SkinDiaryProvider>();
    await provider.fetchMonthlyDiaries(date.year, date.month);
  }

  /// [#2] 선택된 날짜의 기존 다이어리를 불러오고, 있으면 폼에 반영
  Future<void> _loadDiaryForDate(DateTime date) async {
    final provider = context.read<SkinDiaryProvider>();
    await provider.fetchDiaryByDate(date);

    if (!mounted) return;

    final diary = provider.currentDiary;
    if (diary != null) {
      // DB에서 불러온 데이터를 폼에 반영
      setState(() {
        _skinScore = diary.skinScore;
        _sleepHours = (diary.sleepTimeMinutes ?? 0) / 60.0;
        _waterLiters = (diary.waterIntakeMl ?? 0) / 1000.0;
        _dietController.text = diary.diet.join(', ');
        _selectedProductIds.clear();
        _selectedProductIds.addAll(diary.usedCosmetics.map((c) => c.id));
      });
    } else {
      // [#1] 기록이 없으면 디폴트 0으로 초기화
      setState(() {
        _skinScore = 0;
        _sleepHours = 0.0;
        _waterLiters = 0.0;
        _dietController.clear();
        _selectedProductIds.clear();
      });
    }
  }

  /// 날짜 변경 처리 (애니메이션 방향 계산 포함)
  void _changeDate(DateTime newDate) {
    if (newDate.year == _selectedDate.year &&
        newDate.month == _selectedDate.month &&
        newDate.day == _selectedDate.day) return;

    setState(() {
      // [#3] 새 날짜가 기존보다 미래인지 판단하여 애니메이션 방향 결정
      _slideForward = newDate.isAfter(_selectedDate);
      _selectedDate = newDate;
    });

    _loadDiaryForDate(newDate);

    // 월이 바뀌면 기록 날짜도 새로 조회
    if (newDate.month != _selectedDate.month || newDate.year != _selectedDate.year) {
      _loadMonthlyRecords(newDate);
    }
  }

  // [#2] 데이터 저장 후 DB에서 다시 불러오기
  Future<void> _submitDiary() async {
    final int sleepTimeMinutes = (_sleepHours * 60).toInt();
    final int waterIntakeMl = (_waterLiters * 1000).toInt();
    final List<String> dietList = _dietController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final request = SkinDiaryRequest(
      recordDate: _selectedDate.toUtc(),
      skinScore: _skinScore,
      skinImageUrl: null,
      sleepTimeMinutes: sleepTimeMinutes,
      waterIntakeMl: waterIntakeMl,
      diet: dietList,
      usedProductIds: _selectedProductIds,
    );

    final provider = context.read<SkinDiaryProvider>();

    try {
      if (provider.currentDiary != null) {
        await provider.updateDiary(provider.currentDiary!.skinDiaryId, request);
      } else {
        await provider.createDiary(request);
      }

      if (!mounted) return;

      // [#2] 저장 성공 후 DB에서 다시 불러와서 화면에 반영
      await _loadDiaryForDate(_selectedDate);

      // [#5] 저장 후 이번 달 기록 날짜도 갱신 (새 기록이 추가됐으므로 force)
      await provider.fetchMonthlyDiaries(
        _selectedDate.year,
        _selectedDate.month,
        force: true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록이 저장되었습니다.'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diaryProvider = context.watch<SkinDiaryProvider>();
    final bool isLoading = diaryProvider.isLoading;
    final List<dynamic> availableProducts = [];

    return Scaffold(
      backgroundColor: AppColors.background,
      // [#3] 좌우 스와이프로 날짜 이동
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -100) {
            // 왼쪽으로 스와이프 → 다음 날
            _changeDate(_selectedDate.add(const Duration(days: 1)));
          } else if (details.primaryVelocity! > 100) {
            // 오른쪽으로 스와이프 → 이전 날
            _changeDate(_selectedDate.subtract(const Duration(days: 1)));
          }
        },
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
          onRefresh: () async {
            await _loadDiaryForDate(_selectedDate);
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 날짜 선택기 (주간 달력)
                _buildDateSelector(diaryProvider),
                const SizedBox(height: 24),

                // 2. 다이어리 입력 폼 — [#3] AnimatedSwitcher로 날짜 전환 애니메이션
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    // 슬라이드 방향에 따라 좌→우 또는 우→좌 애니메이션
                    final offsetTween = Tween<Offset>(
                      begin: Offset(_slideForward ? 1.0 : -1.0, 0.0),
                      end: Offset.zero,
                    );
                    return SlideTransition(
                      position: offsetTween.animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                      ),
                      child: child,
                    );
                  },
                  // [중요] key가 바뀌어야 AnimatedSwitcher가 전환 애니메이션을 실행함
                  child: _buildRecordCard(
                    availableProducts,
                    key: ValueKey<String>(
                      '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // [#4] 주간 날짜 선택기 — 7일(월~일) 표시 + [#5] 기록 밑줄 표시
  // =========================================================================
  Widget _buildDateSelector(SkinDiaryProvider provider) {
    const List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final DateTime today = DateTime.now();

    // [#4] 선택된 날짜가 속한 주의 월요일 계산
    // DateTime.weekday: 1(월) ~ 7(일)
    final int daysFromMonday = _selectedDate.weekday - 1;
    final DateTime monday = _selectedDate.subtract(Duration(days: daysFromMonday));

    // 월요일부터 7일 생성
    final List<DateTime> displayDays = List.generate(7, (index) {
      return monday.add(Duration(days: index));
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: displayDays.map((date) {
        final bool isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        final bool isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;

        // [#5] 이 날짜에 기록이 있는지 확인
        final bool hasRecord = provider.recordedDays.contains(date.day) &&
            date.month == _selectedDate.month &&
            date.year == _selectedDate.year;

        return GestureDetector(
          onTap: () => _changeDate(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44, // 7일이므로 기존 54에서 축소
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
                    color: isSelected
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
                    color: isSelected ? Colors.white : AppColors.textTitle,
                  ),
                ),
                const SizedBox(height: 4),
                // [#5] 기록이 있으면 밑줄(작은 바) 표시
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: hasRecord ? 16 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================================
  // 다이어리 기록 폼 (Record Card)
  // [#3] key 파라미터 추가 — AnimatedSwitcher가 날짜 변경을 감지하기 위해 필수
  // =========================================================================
  Widget _buildRecordCard(List<dynamic> availableProducts, {Key? key}) {
    final bool isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    final String cardTitle = isToday
        ? '오늘의 기록'
        : DateFormat('M월 d일 기록').format(_selectedDate);

    return Container(
      key: key,
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
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cardTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textTitle,
            ),
          ),
          const SizedBox(height: 24),

          // 1. 수면 시간
          _buildSliderField(
            icon: Icons.bedtime,
            iconColor: Colors.indigo.shade400,
            title: '수면 시간',
            value: _sleepHours,
            unit: '시간',
            min: 0,
            max: 12,
            divisions: 24,
            activeColor: Colors.indigo.shade500,
            onChanged: (val) => setState(() => _sleepHours = val),
          ),
          const SizedBox(height: 24),

          // 2. 물 섭취량
          _buildSliderField(
            icon: Icons.water_drop,
            iconColor: Colors.blue.shade400,
            title: '물 섭취량',
            value: _waterLiters,
            unit: 'L',
            min: 0,
            max: 4,
            divisions: 20,
            activeColor: Colors.blue.shade500,
            onChanged: (val) => setState(() => _waterLiters = val),
          ),
          const SizedBox(height: 24),

          // 3. 식단
          const Row(
            children: [
              Icon(Icons.restaurant, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text('식단',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _dietController,
            decoration: InputDecoration(
              hintText: '먹은 음식을 기록하세요 (쉼표로 구분)',
              hintStyle:
              const TextStyle(fontSize: 13, color: AppColors.textSub1),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: 24),

          // 4. 바른 화장품
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: Colors.purple),
              SizedBox(width: 8),
              Text('바른 화장품',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBody)),
            ],
          ),
          const SizedBox(height: 12),
          if (availableProducts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12)),
              child: const Text('등록된 화장품이 없습니다.',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final product = availableProducts[index];
                  final isSelected =
                  _selectedProductIds.contains(product.id);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedProductIds.remove(product.id);
                        } else {
                          _selectedProductIds.add(product.id);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                clipBehavior: Clip.antiAlias,
                                child: (product.imageUrl != null &&
                                    product.imageUrl!.isNotEmpty)
                                    ? Image.network(product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image,
                                        size: 16,
                                        color: Colors.grey))
                                    : const Icon(Icons.shopping_bag,
                                    size: 16, color: Colors.grey),
                              ),
                              const Spacer(),
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textBody,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          if (isSelected)
                            const Positioned(
                              top: 0,
                              right: 0,
                              child: Icon(Icons.check_circle,
                                  size: 16, color: AppColors.primary),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),

          // 5. 사진 & 피부 점수
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.grey),
                        SizedBox(height: 4),
                        Text('피부 사진',
                            style:
                            TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('피부 점수',
                          style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          int score = index + 1;
                          bool isActive = _skinScore >= score;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _skinScore = score),
                            child: AnimatedContainer(
                              duration:
                              const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 2),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$score',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          );
                        }),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 저장 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitDiary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('기록 저장하기',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  // 공통 슬라이더
  Widget _buildSliderField({
    required IconData icon,
    required Color iconColor,
    required String title,
    required double value,
    required String unit,
    required double min,
    required double max,
    required int divisions,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBody)),
              ],
            ),
            Text(
              '${value.toStringAsFixed(value == value.truncateToDouble() ? 0 : 1)}$unit',
              style: TextStyle(fontWeight: FontWeight.bold, color: activeColor),
            )
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
            thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 10, elevation: 2),
            tickMarkShape: SliderTickMarkShape.noTickMark,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        )
      ],
    );
  }
}