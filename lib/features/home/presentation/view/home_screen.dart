import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../features/auth/domain/enums/skin_concern.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/ingredient_detail_model.dart';
import '../../data/repositories/cosmetics_repository.dart';
import '../../../mypage/data/repositories/member_repository.dart';
import '../providers/home_provider.dart';
import '../widgets/ingredient_info_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CosmeticsRepository>();
    final authProvider = context.read<AuthProvider>();
    final userSkinConcerns = authProvider.skinConcerns;

    return ChangeNotifierProvider(
      create: (_) => HomeProvider(
        repository,
        userSkinConcerns: userSkinConcerns,
      )..init(),
      child: _HomeView(
        nickname: authProvider.nickname,
        userSkinConcerns: userSkinConcerns,
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  final String nickname;
  final List<SkinConcern> userSkinConcerns;

  const _HomeView({
    required this.nickname,
    required this.userSkinConcerns,
  });

  // ── 피부 고민 수정 바텀시트 ──
  void _showEditConcernsSheet(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final memberRepository = context.read<MemberRepository>();
    final selected = Set<SkinConcern>.from(authProvider.skinConcerns);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _SkinConcernEditSheet(
          initialSelected: selected,
          onSave: (concerns) async {
            try {
              await memberRepository.updateSkinConcerns(concerns);
              authProvider.onSkinConcernsUpdated(concerns);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('피부 고민이 수정되었습니다.')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('수정에 실패했습니다. 다시 시도해주세요.')),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildConcernSection(
      SkinConcern concern,
      List<IngredientDetailModel> details, {
        bool isFirst = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 14),
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => await provider.init(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [

            // ── 피부 고민 뱃지 + 수정 버튼 (로그인 + 고민 설정된 경우) ──
            if (userSkinConcerns.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: userSkinConcerns.map((concern) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                concern.displayName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showEditConcernsSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '고민 수정',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSub2,
                                ),
                              ),
                              SizedBox(width: 1),
                              Icon(
                                Icons.keyboard_arrow_right_rounded,
                                color: AppColors.textSub2,
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── 헤더 ──
            if (userSkinConcerns.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textTitle,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: nickname.isNotEmpty ? nickname : '회원',
                          style: const TextStyle(color: AppColors.primary),
                        ),
                        const TextSpan(text: '님에게 딱 맞는 피부 공식'),
                      ],
                    ),
                  ),
                ),
              ),

            // ── 고민별 섹션 (로그인 + 고민 설정된 경우) ──
            if (userSkinConcerns.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final concern = userSkinConcerns[index];
                    final details =
                        provider.recommendedDetailMap[concern] ?? [];
                    return _buildConcernSection(
                      concern,
                      details,
                      isFirst: index == 0,
                    );
                  },
                  childCount: userSkinConcerns.length,
                ),
              ),

            // ── Psik 추천 성분 (기타 or 비로그인 전체) ──
            if (provider.otherIngredientDetails.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userSkinConcerns.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        textBaseline: TextBaseline.ideographic,
                        children: [
                          Container(
                            width: 3.5,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SvgPicture.asset(
                            'assets/images/psik_text_logo.svg',
                            height: 38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            userSkinConcerns.isNotEmpty
                                ? '이 추천하는 모든 성분'
                                : '이 추천하는 피부공식',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textTitle,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSub2,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(42, 0, 42, 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: IngredientInfoCard(
                          detail: provider.otherIngredientDetails[index],
                        ),
                      );
                    },
                    childCount: provider.otherIngredientDetails.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }
}

// ── 피부 고민 수정 바텀시트 ──
class _SkinConcernEditSheet extends StatefulWidget {
  final Set<SkinConcern> initialSelected;
  final Future<void> Function(List<SkinConcern>) onSave;

  const _SkinConcernEditSheet({
    required this.initialSelected,
    required this.onSave,
  });

  @override
  State<_SkinConcernEditSheet> createState() => _SkinConcernEditSheetState();
}

class _SkinConcernEditSheetState extends State<_SkinConcernEditSheet> {
  late Set<SkinConcern> _selected;
  bool _isSaving = false;
  static const int _max = 3;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Row(
              children: [
                const Text(
                  '피부 고민 수정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textTitle,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selected.length}/$_max',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _selected.length == _max
                        ? AppColors.primary
                        : AppColors.textSub2,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 24, bottom: 16),
            child: Text(
              '최소 1개, 최대 3개까지 선택 가능해요.',
              style: TextStyle(fontSize: 13, color: AppColors.textSub2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: SkinConcern.values.map((concern) {
                  final isSelected = _selected.contains(concern);
                  final isDisabled = !isSelected && _selected.length >= _max;
                  return GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () {
                      setState(() {
                        if (isSelected) {
                          _selected.remove(concern);
                        } else {
                          _selected.add(concern);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : isDisabled
                            ? const Color(0xFFF3F4F6)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        concern.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : isDisabled
                              ? AppColors.textSub1
                              : AppColors.textBody,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_isSaving || _selected.isEmpty)
                    ? null
                    : () async {
                  setState(() => _isSaving = true);
                  await widget.onSave(_selected.toList());
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  '저장',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}