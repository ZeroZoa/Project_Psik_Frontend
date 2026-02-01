import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/social_login_button.dart';
import '../../data/services/auth_service.dart'; // AuthService 위치에 맞게 수정해주세요

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // 공통 로그인 처리 핸들러
  Future<void> _handleLogin(BuildContext context, Future<bool> Function() loginMethod) async {
    //서비스 로직 실행
    final isSuccess = await loginMethod();

    //비동기 갭(Async Gap) 방지: 로직 수행 동안 화면이 닫혔는지 체크
    if (!context.mounted) return;

    //결과에 따른 UI 처리
    if (isSuccess) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // 실패 시: 스낵바 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인에 실패했습니다. 다시 시도해 주세요.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 싱글톤 AuthService 인스턴스 가져오기
    final authService = AuthService();

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;
    final contentWidth = isWideScreen ? screenWidth * 0.7 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: contentWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 로고 영역
                  SvgPicture.asset(
                    'assets/images/psik_text_logo.svg',
                    width: 150,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 100),
                  const Text(
                    '3초만에 간단하게 계속하기!',
                    style: TextStyle(
                      color: AppColors.textSub2,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 소셜 로그인 버튼 영역
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //카카오 로그인 버튼
                      SocialLoginButton(
                        assetPath: 'assets/images/kakao_login.svg',
                        backgroundColor: const Color(0xFFFEE500), // 카카오 노랑
                        padding: 12.0,
                        onTap: () => _handleLogin(context, authService.loginWithKakao),
                      ),

                      const SizedBox(width: 12),

                      //구글 로그인 버튼
                      SocialLoginButton(
                        assetPath: 'assets/images/google_login.svg',
                        backgroundColor: Colors.white,
                        hasBorder: true,
                        padding: 0,
                        onTap: () => _handleLogin(context, authService.loginWithGoogle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 1,
                    color: AppColors.textSub2,
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
