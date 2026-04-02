import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'social_login_button.dart';

/// 인증이 필요한 행동 전에 호출하는 헬퍼 함수
/// 이미 인증되어 있으면 true 반환, 아니면 바텀시트 모달 표시
Future<bool> requireLogin(BuildContext context) async {
  final authProvider = context.read<AuthProvider>();
  if (authProvider.isAuthenticated) return true;

  await showLoginModal(context);
  return authProvider.isAuthenticated;
}

/// 로그인 바텀시트 모달 표시
Future<void> showLoginModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => const _LoginModalContent(),
  );
}

class _LoginModalContent extends StatelessWidget {
  const _LoginModalContent();

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).padding.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 핸들바
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          SvgPicture.asset(
            'assets/images/psik_text_logo.svg',
            width: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),

          const Text(
            '로그인이 필요한 서비스입니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textTitle,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '소셜 계정으로 간편하게 시작하세요',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SocialLoginButton(
                assetPath: 'assets/images/kakao_login.svg',
                backgroundColor: const Color(0xFFFEE500),
                padding: 12.0,
                onTap: () {
                  Navigator.pop(context);
                  authService.loginWithKakaoWeb();
                },
              ),
              const SizedBox(width: 16),
              SocialLoginButton(
                assetPath: 'assets/images/google_login.svg',
                backgroundColor: Colors.white,
                hasBorder: true,
                padding: 0,
                onTap: () {
                  Navigator.pop(context);
                  authService.loginWithGoogleWeb();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}