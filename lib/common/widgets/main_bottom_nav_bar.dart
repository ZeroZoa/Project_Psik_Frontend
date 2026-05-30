import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
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
        showSelectedLabels: false,
        showUnselectedLabels: false,  // 이미 있으면 false로 변경
        selectedFontSize: 0,
        unselectedFontSize: 0,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Symbols.home, size: 28),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.chat_bubble, size: 24),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.search, size: 27),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.list_alt, size: 26),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Symbols.person, size: 28),
            label: '',
          ),
        ],
      ),
    );
  }
}