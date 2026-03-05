import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skinner_frontend/features/diary/presentation/view/skin_diary_screen.dart';

// [Auth]
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/view/login_screen.dart';
import '../../features/splash/presentation/view/splash_screen.dart';

// [Widgets] 상단/하단 네비게이션 바 직접 임포트
import '../../common/widgets/main_bottom_nav_bar.dart';
import '../../common/widgets/main_top_nav_bar.dart';

// [Content - 각 탭 화면]
import '../../features/home/presentation/view/home_screen.dart';

import '../../features/community/presentation/view/post_list_screen.dart';
import '../../features/community/presentation/view/post_detail_screen.dart';
import '../../features/community/presentation/view/post_write_screen.dart';
import '../../features/community/data/models/post_model.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,

      //리다이렉트 로직
      redirect: (context, state) {
        final isLoading = authProvider.isLoading;
        final isAuthenticated = authProvider.isAuthenticated;
        final isSplash = state.uri.toString() == '/splash';
        final isLogin = state.uri.toString() == '/login';

        if (isLoading) return '/splash';
        if (!isAuthenticated) return isLogin ? null : '/login';
        if (isSplash || isLogin) return '/home';
        return null;
      },

      routes: [
        // 스플래시 & 로그인 (네비게이션 바 없음)
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/community/write',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final editPost = state.extra as PostModel?;
            return PostWriteScreen(editPost: editPost);
          },
        ),
        // 커뮤니티 — 상세 (전체 화면, 하단바 없음)
        GoRoute(
          path: '/community/:postId',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final postId = int.parse(state.pathParameters['postId']!);
            return PostDetailScreen(postId: postId);
          },
        ),

        // [2] 핵심: ShellRoute (여기서 네비게이션 바 고정!)
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          // MainScreen 파일 없이, 여기서 직접 레이아웃을 잡습니다.
          builder: (context, state, child) {
            // 1. 현재 URL을 보고 인덱스 계산
            final String location = state.uri.toString();
            int currentIndex = 0;
            if (location.startsWith('/search')) currentIndex = 1;
            else if (location.startsWith('/skin-diary')) currentIndex = 2;
            else if (location.startsWith('/mypage')) currentIndex = 3;

            // 2. 공통 Scaffold 반환 (상/하단바 고정)
            return Scaffold(
              backgroundColor: Colors.white,

              // [상단바]
              appBar: const MainTopNavBar(),

              // [본문] (HomeScreen, SearchScreen 등이 교체됨)
              body: child,

              // [하단바] (모든 탭에서 고정)
              bottomNavigationBar: MainBottomNavBar(
                currentIndex: currentIndex,
              ),
            );
          },
          routes: [
            // 탭 1: 홈
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            // 탭 2: 커뮤니티
            GoRoute(
              path: '/community',
              builder: (context, state) => const PostListScreen(),
            ),
            // 탭 3: 검색
            GoRoute(
              path: '/search',
              builder: (context, state) => const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: Text("검색 화면")),
              ),
            ),
            // 탭 4: 스킨로그
            GoRoute(
              path: '/skin-diary',
              builder: (context, state) => const SkinDiaryScreen(),
            ),
            // 탭 5: 마이페이지
            GoRoute(
              path: '/mypage',
              builder: (context, state) => Center(
                child: ElevatedButton(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  child: const Text("로그아웃"),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}