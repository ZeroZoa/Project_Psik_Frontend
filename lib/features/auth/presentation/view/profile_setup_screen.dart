import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/theme/app_colors.dart';
import '../../domain/enums/skin_type.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();

  SkinType? _selectedSkinType; // 이제 import한 Enum을 타입으로 사용
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkinType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피부 타입을 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Spring API 호출 (나중에 구현)
      // print("전송 데이터: ${_selectedSkinType!.name}"); // 예: DRY, OILY

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로필 설정'),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '마지막 단계입니다!\n닉네임과 피부 타입을\n설정해주세요.',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                  const SizedBox(height: 40),

                  // 1. 닉네임 입력
                  const Text('닉네임', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nicknameController,
                    maxLength: 10,
                    decoration: InputDecoration(
                      hintText: '한글/영문 2~10자',
                      counterText: "",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return '닉네임을 입력해주세요.';
                      if (value.length < 2) return '닉네임은 2글자 이상이어야 합니다.';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // 2. 피부 타입 선택
                  const Text('피부 타입', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    // SkinType Enum의 값들을 순회하며 Chip 생성
                    children: SkinType.values.map((type) {
                      final isSelected = _selectedSkinType == type;
                      return ChoiceChip(
                        label: Text(
                          type.displayName, // '건성', '지성' 등 표시
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) _selectedSkinType = type;
                          });
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : Colors.grey.shade300,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 60),

                  // 3. 완료 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 24, width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text(
                        '시작하기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}