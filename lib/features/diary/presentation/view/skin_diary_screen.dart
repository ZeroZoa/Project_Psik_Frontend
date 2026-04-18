import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/login_modal.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/skin_diary_request.dart';
import '../providers/skin_analysis_provider.dart';
import '../providers/skin_diary_provider.dart';

class SkinDiaryScreen extends StatefulWidget {
  const SkinDiaryScreen({super.key});

  @override
  State<SkinDiaryScreen> createState() => _SkinDiaryScreenState();
}

class _SkinDiaryScreenState extends State<SkinDiaryScreen> {
  DateTime _selectedDate = DateTime.now();

  double _sleepHours = 0.0;
  double _waterLiters = 0.0;
  final TextEditingController _dietController = TextEditingController();
  final List<int> _selectedProductIds = [];
  int _skinScore = 0;
  XFile? _selectedImage;

  bool _slideForward = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
      if (isAuthenticated) {
        _loadDiaryForDate(_selectedDate);
        _loadMonthlyRecords(_selectedDate);
      }
    });
  }

  @override
  void dispose() {
    _dietController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthlyRecords(DateTime date) async {
    final provider = context.read<SkinDiaryProvider>();
    await provider.fetchMonthlyDiaries(date.year, date.month);
  }

  Future<void> _loadDiaryForDate(DateTime date) async {
    final provider = context.read<SkinDiaryProvider>();
    await provider.fetchDiaryByDate(date);

    if (!mounted) return;

    final diary = provider.currentDiary;
    if (diary != null) {
      setState(() {
        _skinScore = diary.skinScore;
        _sleepHours = (diary.sleepTimeMinutes ?? 0) / 60.0;
        _waterLiters = (diary.waterIntakeMl ?? 0) / 1000.0;
        _dietController.text = diary.diet.join(', ');
        _selectedProductIds.clear();
        _selectedProductIds.addAll(diary.usedCosmetics.map((c) => c.id));
        _selectedImage = null;
      });
      if (!mounted) return;
      await context.read<SkinAnalysisProvider>().fetchAnalysis(diary.skinDiaryId);
    } else {
      setState(() {
        _skinScore = 0;
        _sleepHours = 0.0;
        _waterLiters = 0.0;
        _dietController.clear();
        _selectedProductIds.clear();
        _selectedImage = null;
      });
      if (!mounted) return;
      context.read<SkinAnalysisProvider>().reset();
    }
  }

  void _changeDate(DateTime newDate) {
    if (newDate.year == _selectedDate.year &&
        newDate.month == _selectedDate.month &&
        newDate.day == _selectedDate.day) {
      return;
    }

    final DateTime oldDate = _selectedDate;

    setState(() {
      _slideForward = newDate.isAfter(_selectedDate);
      _selectedDate = newDate;
    });

    _loadDiaryForDate(newDate);

    if (newDate.month != oldDate.month || newDate.year != oldDate.year) {
      _loadMonthlyRecords(newDate);
    }
  }

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
      sleepTimeMinutes: sleepTimeMinutes,
      waterIntakeMl: waterIntakeMl,
      diet: dietList,
      usedProductIds: _selectedProductIds,
    );

    final provider = context.read<SkinDiaryProvider>();
    final XFile? imageToAnalyze = _selectedImage;

    try {
      if (provider.currentDiary != null) {
        await provider.updateDiary(provider.currentDiary!.skinDiaryId, request);
      } else {
        await provider.createDiary(request);
      }

      await _loadDiaryForDate(_selectedDate);
      await provider.fetchMonthlyDiaries(
        _selectedDate.year,
        _selectedDate.month,
        force: true,
      );

      if (!mounted) return;

      // 이미지 선택 시 분석 API 호출 (저장 성공 후에만)
      if (imageToAnalyze != null && provider.currentDiary != null) {
        await context.read<SkinAnalysisProvider>().analyze(
          provider.currentDiary!.skinDiaryId,
          imageToAnalyze,
        );

        if (!mounted) return;

        final analysisError = context.read<SkinAnalysisProvider>().errorMessage;
        if (analysisError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('피부 분석 실패: $analysisError'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기록이 저장되었습니다.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    if (!isAuthenticated) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text(
                '로그인이 필요해요!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => showLoginModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 13),
                ),
                icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                label: const Text(
                  '로그인하기',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final diaryProvider = context.watch<SkinDiaryProvider>();
    final bool isLoading = diaryProvider.isLoading;
    final List<dynamic> availableProducts = [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -100) {
            _changeDate(_selectedDate.add(const Duration(days: 1)));
          } else if (details.primaryVelocity! > 100) {
            _changeDate(_selectedDate.subtract(const Duration(days: 1)));
          }
        },
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
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
                      _buildDateSelector(diaryProvider),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          final offsetTween = Tween<Offset>(
                            begin: Offset(_slideForward ? 1.0 : -1.0, 0.0),
                            end: Offset.zero,
                          );
                          return SlideTransition(
                            position: offsetTween.animate(
                              CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut),
                            ),
                            child: child,
                          );
                        },
                        child: _buildRecordCard(
                          availableProducts,
                          key: ValueKey<String>(
                            '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                          ),
                        ),
                      ),
                      _buildAnalysisCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // =========================================================================
  // 주간 날짜 선택기
  // =========================================================================
  Widget _buildDateSelector(SkinDiaryProvider provider) {
    const List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final DateTime today = DateTime.now();
    final DateTime startDay = _selectedDate.subtract(const Duration(days: 3));
    final List<DateTime> displayDays =
        List.generate(7, (index) => startDay.add(Duration(days: index)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: displayDays.map((date) {
        final bool isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
        final bool isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final bool hasRecord = provider.recordedDays.contains(date.day) &&
            date.month == _selectedDate.month &&
            date.year == _selectedDate.year;

        return GestureDetector(
          onTap: () => _changeDate(date),
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
        );
      }).toList(),
    );
  }

  // =========================================================================
  // 다이어리 기록 폼
  // =========================================================================
  Widget _buildRecordCard(List<dynamic> availableProducts, {Key? key}) {
    final bool isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    final String cardTitle =
        isToday ? '오늘의 기록' : DateFormat('M월 d일 기록').format(_selectedDate);

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
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
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
                  borderRadius: BorderRadius.circular(14)),
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
                  final isSelected = _selectedProductIds.contains(product.id);
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
                        borderRadius: BorderRadius.circular(14),
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
                                                size: 16, color: Colors.grey))
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
                child: Builder(
                  builder: (context) {
                    final alreadyAnalyzed =
                        context.watch<SkinAnalysisProvider>().analysis != null;
                    return GestureDetector(
                      onTap: alreadyAnalyzed
                          ? null
                          : () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 70,
                              );
                              if (picked != null) {
                                setState(() => _selectedImage = picked); // XFile 그대로 저장
                              }
                            },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: alreadyAnalyzed
                              ? Colors.grey.shade200
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: kIsWeb
                              ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                              : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                        )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined,
                                      color: alreadyAnalyzed
                                          ? Colors.grey.shade400
                                          : Colors.grey),
                                  const SizedBox(height: 4),
                                  Text(
                                    alreadyAnalyzed ? '분석 완료' : '피부 사진',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: alreadyAnalyzed
                                            ? Colors.grey.shade400
                                            : Colors.grey),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
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
                              duration: const Duration(milliseconds: 200),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2),
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
                    borderRadius: BorderRadius.circular(14)),
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

  // =========================================================================
  // 피부 분석 결과 카드
  // =========================================================================
  Widget _buildAnalysisCard() {
    final analysisProvider = context.watch<SkinAnalysisProvider>();
    final analysis = analysisProvider.analysis;

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
          )
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

          // 분석 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              analysis.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppColors.surface,
                child: const Center(
                  child:
                      Icon(Icons.broken_image, color: Colors.grey, size: 48),
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
            _buildAnalysisItem('여드름 점수', '${analysis.acneScore ?? 0}점',
                analysis.acneScore ?? 0, AppColors.error),
            _buildAnalysisItem('주름 점수', '${analysis.wrinkleScore ?? 0}점',
                analysis.wrinkleScore ?? 0, Colors.orange),
            _buildAnalysisItem('피부결 점수', '${analysis.toneScore ?? 0}점',
                analysis.toneScore ?? 0, Colors.purple),
            _buildAnalysisItem('유수분 점수', '${analysis.oilScore ?? 0}점',
                analysis.oilScore ?? 0, Colors.blue),
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

  // =========================================================================
  // 분석 항목 한 줄 위젯
  // =========================================================================
  Widget _buildAnalysisItem(
      String label, String value, int score, Color color) {
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

  // =========================================================================
  // 공통 슬라이더
  // =========================================================================
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
        )
      ],
    );
  }
}
