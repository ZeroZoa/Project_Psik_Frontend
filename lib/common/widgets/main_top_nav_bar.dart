import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

class MainTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const MainTopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white, // 스크롤 시 색상 변경 방지
      elevation: 0,
      centerTitle: false,
      title: SvgPicture.asset(
        'assets/images/psik_text_logo.svg',
        height: 32,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textTitle),
          onPressed: () {
            // 알림 페이지 이동 로직
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}