import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

// 화면들 임포트
import 'package:skinner_frontend/features/auth/presentation/view/login_screen.dart';
// import '../../features/splash/presentation/view/splash_screen.dart'; // 곧 만들 예정
// import '../../features/home/presentation/view/home_screen.dart';     // 곧 만들 예정

class AppRouter {
  // 다이얼로그나 오버레이를 띄울 때 context 문제 없이 쓰기 위해 전역 키를 사용
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',

    routes: [
      //스플래시 (자동 로그인 체크)
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(body: Center(child: Text("Splash Screen (Temp)"))), // 임시
      ),

      //로그인
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      //홈 (로그인 성공 후 이동)
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Center(child: Text("Home Screen (Temp)"))), // 임시
      ),
    ],
  );
}