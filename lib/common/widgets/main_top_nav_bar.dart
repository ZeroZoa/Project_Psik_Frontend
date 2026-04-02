import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'login_modal.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  const MainTopNavBar({super.key});

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
        // if (isAuthenticated)
        // // 로그인 상태: 알림 아이콘
        //   IconButton(
        //     color: AppColors.textSub2,
        //     icon: Icon(LucideIcons.bell),
        //     onPressed: () {
        //       // TODO: 알림 페이지 이동
        //     },
        //   )
        // else
        // // 비로그인 상태: 로그인 버튼
        //   IconButton(
        //     color: AppColors.textSub2,
        //     icon: Icon(LucideIcons.logIn),
        //       onPressed: () => showLoginModal(context),
        //   ),
        if (!isAuthenticated)
        // 로그인 상태: 알림 아이콘
          IconButton(
            color: AppColors.textSub2,
            icon: Icon(LucideIcons.logIn),
            onPressed: () => showLoginModal(context),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}