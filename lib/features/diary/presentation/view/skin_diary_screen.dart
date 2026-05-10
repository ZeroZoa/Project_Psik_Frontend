import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/login_modal.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/data/repositories/member_product_repository.dart';
import '../../data/models/skin_diary_request.dart';
import '../providers/skin_analysis_provider.dart';
import '../providers/skin_diary_provider.dart';
import '../widgets/diary_date_selector.dart';
import '../widgets/diary_slider_field.dart';
import '../widgets/diary_analysis_card.dart';


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
  List<ProductModel> _searchedProducts = [];
  bool _isProductSearchLoading = false;

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

  Future<void> _searchProducts(String keyword) async {
    setState(() => _isProductSearchLoading = true);
    try {
      final products = await context
          .read<MemberProductRepository>()
          .searchProducts(keyword: keyword.isEmpty ? null : keyword);
      if (!mounted) return;
      setState(() => _searchedProducts = products);
    } catch (e) {
      debugPrint('제품 검색 실패: $e');
    } finally {
      if (mounted) setState(() => _isProductSearchLoading = false);
    }
  }

  Future<void> _openProductSearchSheet() async {
    await _searchProducts('');
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      // 핸들
                      Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Text('화장품 선택',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      // 검색창
                      TextField(
                        onChanged: (value) async {
                          await _searchProducts(value);
                          setSheetState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: '제품명 또는 브랜드 검색',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 선택된 제품 칩
                      if (_selectedProductIds.isNotEmpty)
                        SizedBox(
                          height: 36,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _searchedProducts
                                .where((p) => _selectedProductIds.contains(p.id))
                                .map((p) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(p.name,
                                    style: const TextStyle(fontSize: 12)),
                                backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                                deleteIconColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                onDeleted: () {
                                  setState(() => _selectedProductIds.remove(p.id));
                                  setSheetState(() {});
                                },
                              ),
                            ))
                                .toList(),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // 제품 목록
                      Expanded(
                        child: _isProductSearchLoading
                            ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))
                            : _searchedProducts.isEmpty
                            ? const Center(
                            child: Text('검색 결과가 없습니다.',
                                style: TextStyle(
                                    color: AppColors.textSub2)))
                            : ListView.separated(
                          controller: scrollController,
                          itemCount: _searchedProducts.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: Colors.grey.shade100, height: 1),
                          itemBuilder: (context, index) {
                            final product = _searchedProducts[index];
                            final isSelected =
                            _selectedProductIds.contains(product.id);
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 44, height: 44,
                                  color: AppColors.surface,
                                  child: product.imageUrl != null
                                      ? Image.network(product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.shopping_bag,
                                          color: Colors.grey))
                                      : const Icon(Icons.shopping_bag,
                                      color: Colors.grey),
                                ),
                              ),
                              title: Text(product.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              subtitle: product.brand != null
                                  ? Text(product.brand!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSub2))
                                  : null,
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle,
                                  color: AppColors.primary)
                                  : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.grey),
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedProductIds.remove(product.id);
                                  } else {
                                    _selectedProductIds.add(product.id);
                                  }
                                });
                                setSheetState(() {});
                              },
                            );
                          },
                        ),
                      ),
                      // 확인 버튼
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 16,
                            top: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('${_selectedProductIds.length}개 선택 완료',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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
        // 기존 선택 제품을 _searchedProducts에 동기화 (칩 이름 표시용)
        _searchedProducts = diary.usedCosmetics
            .map((c) => ProductModel(id: c.id, name: c.name, brand: c.brand, imageUrl: c.imageUrl))
            .toList();
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
              Icon(Icons.lock_outline, size: 100, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text(
                '로그인이 필요해요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => showLoginModal(context),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  foregroundColor: WidgetStateProperty.all(AppColors.primary),
                  overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return AppColors.primary.withValues(alpha: 0.08);
                    }
                    if (states.contains(WidgetState.pressed)) {
                      return AppColors.primary.withValues(alpha: 0.15);
                    }
                    return Colors.transparent;
                  }),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.primary, width: 2),
                  )),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                  elevation: WidgetStateProperty.all(0),
                  shadowColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/images/psik_text_logo.svg',
                      height: 36,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '로그인',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final diaryProvider = context.watch<SkinDiaryProvider>();
    final bool isLoading = diaryProvider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -100) {
            // 앞으로 — 오늘 이후로 못 가게 막기
            final next = _selectedDate.add(const Duration(days: 1));
            final today = DateTime.now();
            final todayNormalized = DateTime(today.year, today.month, today.day);
            final nextNormalized = DateTime(next.year, next.month, next.day);
            if (!nextNormalized.isAfter(todayNormalized)) {
              _changeDate(next);
            }
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
                      DiaryDateSelector(
                        selectedDate: _selectedDate,
                        recordedDays: diaryProvider.recordedDays,
                        onDateChanged: _changeDate,
                      ),
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
                          key: ValueKey<String>(
                            '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                          ),
                        ),
                      ),
                      const DiaryAnalysisCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }



  // =========================================================================
  // 다이어리 기록 폼
  // =========================================================================
  Widget _buildRecordCard({Key? key}) {
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
          DiarySliderField(
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
          DiarySliderField(
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
          GestureDetector(
            onTap: _openProductSearchSheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _selectedProductIds.isEmpty
                  ? const Row(
                children: [
                  Icon(Icons.search, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('제품을 검색해서 추가하세요',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              )
                  : Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selectedProductIds.map((id) {
                  final product =
                      _searchedProducts.where((p) => p.id == id).firstOrNull;
                  return Chip(
                    label: Text(product?.name ?? '#$id',
                        style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    side: const BorderSide(color: AppColors.primary),
                    deleteIconColor: AppColors.primary,
                    onDeleted: () => setState(() => _selectedProductIds.remove(id)),
                  );
                }).toList(),
              ),
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
                                    alreadyAnalyzed ? '분석 완료' : 'AI 피부 분석',
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
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          int score = index + 1;
                          bool isActive = _skinScore >= score;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: ClipOval(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => setState(() => _skinScore = score),
                                  hoverColor: Colors.black.withValues(alpha: 0.95),
                                  splashColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
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
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
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
                shadowColor: Colors.transparent,
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.black.withValues(alpha: 0.12);
                  }
                  return Colors.transparent;
                }),
                elevation: WidgetStateProperty.all(0),
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
}
