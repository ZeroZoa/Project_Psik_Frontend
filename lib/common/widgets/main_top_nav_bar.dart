import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../features/auth/domain/enums/skin_concern.dart';
import '../../features/mypage/data/repositories/member_repository.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'login_modal.dart';

class MainTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isHome;
  const MainTopNavBar({super.key, this.isHome = false});

  @override
  Widget build(BuildContext context) {
    //로그인 상태 감지
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: GestureDetector(
        onTap: () => context.go('/home'),
        child: SvgPicture.asset(
          'assets/images/psik_text_logo.svg',
          height: 40,
        ),
      ),
      actions: [
        // 홈 화면 + 로그인 + 피부고민 설정된 경우 → 고민 수정 버튼
        if (isHome &&
            isAuthenticated &&
            context.watch<AuthProvider>().skinConcerns.isNotEmpty)
          IconButton(
            icon: const Icon(LucideIcons.settings2, size: 23),
            color: AppColors.textSub2,
            onPressed: () => _showEditConcernsSheet(context),
          ),
        if (!isAuthenticated)
          IconButton(
            color: AppColors.textSub2,
            icon: const Icon(LucideIcons.logIn),
            onPressed: () => showLoginModal(context),
          ),
      ],
    );
  }

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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
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