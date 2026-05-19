import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // [필수] 이동 처리를 위해 추가
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;

  //외부에서 함수를 받지 않습니다.
  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  //이동 로직
  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // 같은 탭 누르면 무시

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/community');
        break;
      case 2:
        context.go('/search');
        break;
      case 3:
        context.go('/skin-diary');
        break;
      case 4:
        context.go('/mypage');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) => _onItemTapped(context, index),

        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSub2,
        showSelectedLabels: false,   // 추가
        showUnselectedLabels: false,  // 이미 있으면 false로 변경
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.messagesSquare),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutList),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: '',
          ),
        ],
      ),
    );
  }
}