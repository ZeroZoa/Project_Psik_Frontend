import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../common/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.primary, // 브랜드 컬러
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 (흰색 버전이 있다면 그것 사용)
            SvgPicture.asset(
              'assets/images/psik_text_logo_white.svg',
              width: 180,
              // colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), // 필요시 색상 변경
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}