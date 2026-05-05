import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../auth/domain/enums/gender.dart';
import '../../../auth/domain/enums/skin_concern.dart';
import '../../../auth/domain/enums/skin_type.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mypage/data/repositories/member_repository.dart';

/// 프로필 설정/수정 폼 화면 진입점
/// - [isEditMode] false → 최초 프로필 설정 (닉네임/성별/출생연도/피부타입/피부고민)
/// - [isEditMode] true  → 마이페이지 프로필 수정 (닉네임/피부고민만)
/// - 제출: [MemberRepository.setupProfile] / [MemberRepository.updateNickname] + [MemberRepository.updateSkinConcerns]
class ProfileSetupScreen extends StatefulWidget {
  final bool isEditMode;

  const ProfileSetupScreen({super.key, this.isEditMode = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

/// [ProfileSetupScreen]의 State — 폼 입력값 및 닉네임 중복확인/제출 로직 관리
/// 관리 상태: 닉네임, 출생연도, 성별, 피부타입, 피부고민(최대 3개), 닉네임 중복확인 결과
class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _birthYearController = TextEditingController();

  Gender? _selectedGender;
  SkinType? _selectedSkinType;
  final Set<SkinConcern> _selectedSkinConcerns = {};

  bool _isLoading = false;
  bool _isCheckingNickname = false;
  bool? _isNicknameAvailable;
  String _lastCheckedNickname = '';

  static const int _maxSkinConcerns = 3;

  /// 수정 모드 진입 시 [AuthProvider]에서 기존 닉네임/피부고민을 폼에 바인딩
  /// 기존 닉네임은 중복확인 통과 상태로 초기화
  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      // 기존 정보 미리 채우기
      final authProvider = context.read<AuthProvider>();
      _nicknameController.text = authProvider.nickname;
      _selectedSkinConcerns.addAll(authProvider.skinConcerns);
      // 닉네임은 기존값이므로 중복확인 통과로 처리
      _isNicknameAvailable = true;
      _lastCheckedNickname = authProvider.nickname;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  /// 닉네임 중복 확인 — [MemberRepository.checkNicknameDuplicate] 호출
  /// - 수정 모드에서 기존 닉네임과 동일하면 API 호출 없이 통과 처리
  /// - 결과: _isNicknameAvailable (true/false/null)
  Future<void> _checkNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty || nickname.length < 2) return;

    // 기존 닉네임과 동일하면 바로 통과
    if (widget.isEditMode && nickname == context.read<AuthProvider>().nickname) {
      setState(() {
        _isNicknameAvailable = true;
        _lastCheckedNickname = nickname;
      });
      return;
    }

    setState(() {
      _isCheckingNickname = true;
      _isNicknameAvailable = null;
    });

    try {
      final repo = context.read<MemberRepository>();
      final isDuplicate = await repo.checkNicknameDuplicate(nickname);
      if (!mounted) return;
      setState(() {
        _isNicknameAvailable = !isDuplicate;
        _lastCheckedNickname = nickname;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isNicknameAvailable = null);
      _showSnackBar('닉네임 확인 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isCheckingNickname = false);
    }
  }

  /// 폼 유효성 검사 후 생성/수정 API 호출
  /// - 설정 모드: [MemberRepository.setupProfile] → [AuthProvider.onProfileSetupComplete] → /home 이동
  /// - 수정 모드: 닉네임/피부고민 각각 업데이트 → pop → [AuthProvider.onSkinConcernsUpdated]
  /// - pop을 notifyListeners() 보다 먼저 호출해야 redirect 루프 방지
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_isNicknameAvailable != true) {
      _showSnackBar('닉네임 중복 확인을 완료해주세요.');
      return;
    }
    if (_lastCheckedNickname != _nicknameController.text.trim()) {
      _showSnackBar('닉네임이 변경되었습니다. 다시 중복 확인해주세요.');
      return;
    }
    if (_selectedSkinConcerns.isEmpty) {
      _showSnackBar('피부 고민을 1개 이상 선택해주세요.');
      return;
    }

    if (!widget.isEditMode) {
      if (_selectedGender == null) {
        _showSnackBar('성별을 선택해주세요.');
        return;
      }
      if (_selectedSkinType == null) {
        _showSnackBar('피부 타입을 선택해주세요.');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final repo = context.read<MemberRepository>();
      final authProvider = context.read<AuthProvider>();

      if (widget.isEditMode) {
        // 닉네임 변경된 경우만 업데이트
        if (_nicknameController.text.trim() != authProvider.nickname) {
          await repo.updateNickname(_nicknameController.text.trim());
        }
        // 피부 고민 업데이트
        await repo.updateSkinConcerns(_selectedSkinConcerns.toList());

        if (!mounted) return;
        // pop 먼저 → 그 다음 notifyListeners() 호출해야 redirect 안 타게됨
        context.pop();
        authProvider.onSkinConcernsUpdated(_selectedSkinConcerns.toList());
      } else {
        await repo.setupProfile(
          nickname: _nicknameController.text.trim(),
          gender: _selectedGender!,
          birthYear: int.parse(_birthYearController.text.trim()),
          skinType: _selectedSkinType!,
          skinConcerns: _selectedSkinConcerns.toList(),
        );

        if (!mounted) return;
        authProvider.onProfileSetupComplete(_selectedSkinConcerns.toList());
        if (!mounted) return;
        context.go('/home');
      }
    } on DioException catch (e) {
      _showSnackBar(e.response?.data['message'] ?? '오류가 발생했습니다.');
    } catch (e) {
      _showSnackBar('오류가 발생했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// 폼 섹션 상단 레이블 헬퍼 — 타이틀 + 필수 여부 표시(*)
  Widget _sectionTitle(String title, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textTitle,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.subPrimary,
              ),
            ),
        ],
      ),
    );
  }

  /// 단일 선택 칩 위젯 헬퍼
  /// 성별([Gender]), 피부타입([SkinType]), 피부고민([SkinConcern]) 섹션에서 공통 재사용
  /// 선택 상태에 따라 색상/폰트 애니메이션 적용
  Widget _buildSelectChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textBody,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          automaticallyImplyLeading: widget.isEditMode,
          leading: widget.isEditMode
              ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textTitle, size: 18),
            onPressed: () => context.pop(),
          )
              : null,
          title: Text(
            widget.isEditMode ? '프로필 수정' : '프로필 설정',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textTitle,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.isEditMode) ...[
                          const Text(
                            '환영합니다!\n맞춤 피부 케어를 위해\n정보를 입력해주세요.',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textTitle,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 36),
                        ],

                        // ── 닉네임 ──
                        _sectionTitle('닉네임'),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex:4,
                                child: TextFormField(
                                  controller: _nicknameController,
                                  maxLength: 9,
                                  onChanged: (_) {
                                    if (_isNicknameAvailable != null) {
                                      setState(() => _isNicknameAvailable = null);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: '한글/영문/숫자 2~20자',
                                    counterText: '',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.inputBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.inputBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: AppColors.error),
                                    ),
                                    suffixIcon: _isNicknameAvailable == null
                                        ? null
                                        : Icon(
                                      _isNicknameAvailable!
                                          ? Icons.check_circle_outline
                                          : Icons.cancel_outlined,
                                      color: _isNicknameAvailable!
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return '닉네임을 입력해주세요.';
                                    }
                                    if (value.trim().length < 2) {
                                      return '닉네임은 2자 이상 9자 이하입니다.';
                                    }
                                    final regex = RegExp(r'^[가-힣a-zA-Z0-9_]+$');
                                    if (!regex.hasMatch(value.trim())) {
                                      return '한글, 영문, 숫자, 언더스코어만 사용 가능합니다.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isCheckingNickname ? null : _checkNickname,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                  child: _isCheckingNickname
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                    : const Text('중복확인', style: TextStyle(fontSize: 13)),
                                ),
                              )
                            ],
                          ),
                        ),
                        if (_isNicknameAvailable != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Text(
                              _isNicknameAvailable!
                                  ? '사용 가능한 닉네임입니다.'
                                  : '이미 사용 중인 닉네임입니다.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isNicknameAvailable! ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 28),

                        // ── 최초 설정 전용 필드 ──
                        if (!widget.isEditMode) ...[
                          // 성별
                          _sectionTitle('성별'),
                          Wrap(
                            spacing: 10,
                            children: Gender.values.map((gender) {
                              return _buildSelectChip(
                                label: gender.displayName,
                                isSelected: _selectedGender == gender,
                                onTap: () => setState(() => _selectedGender = gender),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 28),

                          // 출생연도
                          _sectionTitle('출생연도'),
                          TextFormField(
                            controller: _birthYearController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: InputDecoration(
                              hintText: '예) 1998',
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.inputBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.inputBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.error),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '출생연도를 입력해주세요.';
                              }
                              final year = int.tryParse(value.trim());
                              if (year == null) return '숫자만 입력해주세요.';
                              final currentYear = DateTime.now().year;
                              if (year < 1900 || year > currentYear) {
                                return '올바른 출생연도를 입력해주세요.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          // 피부 타입
                          _sectionTitle('피부 타입'),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: SkinType.values.map((type) {
                              return _buildSelectChip(
                                label: type.displayName,
                                isSelected: _selectedSkinType == type,
                                onTap: () => setState(() => _selectedSkinType = type),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 28),
                        ],

                        // ── 피부 고민 ──
                        _sectionTitle('피부 고민'),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Text(
                                '최소 1개, 최대 3개까지 선택 가능해요.',
                                style: TextStyle(fontSize: 13, color: AppColors.textSub2),
                              ),
                              const Spacer(),
                              Text(
                                '${_selectedSkinConcerns.length}/$_maxSkinConcerns',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedSkinConcerns.length == _maxSkinConcerns
                                      ? AppColors.primary
                                      : AppColors.textSub2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: SkinConcern.values.map((concern) {
                            final isSelected = _selectedSkinConcerns.contains(concern);
                            final isMaxReached = _selectedSkinConcerns.length >= _maxSkinConcerns;
                            final isDisabled = !isSelected && isMaxReached;

                            return GestureDetector(
                              onTap: isDisabled
                                  ? () => _showSnackBar('피부 고민은 최대 $_maxSkinConcerns개까지 선택 가능해요.')
                                  : () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedSkinConcerns.remove(concern);
                                  } else {
                                    _selectedSkinConcerns.add(concern);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : isDisabled
                                      ? AppColors.surface.withValues(alpha: 0.5)
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.inputBorder,
                                  ),
                                ),
                                child: Text(
                                  concern.displayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 하단 버튼 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : Text(
                      widget.isEditMode ? '저장' : '시작하기',
                      style: const TextStyle(
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
        ),
      ),
    );
  }
}