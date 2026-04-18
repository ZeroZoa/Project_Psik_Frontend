import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skinner_frontend/features/diary/presentation/view/skin_diary_screen.dart';

import '../../features/admin/presentation/view/admin_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/view/profile_setup_screen.dart';
import '../../features/home/data/models/product_model.dart';
import '../../features/home/presentation/view/product_detail_screen.dart';
import '../../features/mypage/presentation/view/mypage_screen.dart';

import '../../common/widgets/main_bottom_nav_bar.dart';
import '../../common/widgets/main_top_nav_bar.dart';

import '../../features/home/presentation/view/home_screen.dart';
import '../../features/home/presentation/view/ingredient_detail_screen.dart';
import '../../features/community/presentation/view/post_list_screen.dart';
import '../../features/community/presentation/view/post_detail_screen.dart';
import '../../features/community/presentation/view/post_write_screen.dart';
import '../../features/community/data/models/post_model.dart';
import '../../features/search/presentation/view/search_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
  GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
  GlobalKey<NavigatorState>();

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/home',
      refreshListenable: authProvider,

      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final profileComplete = authProvider.profileComplete;
        final location = state.uri.toString();

        // 로그인 됐는데 프로필 미설정 → /profile-setup 강제
        if (isAuthenticated && !profileComplete
            && location != '/profile-setup'
            && !authProvider.isAdmin) {
          return '/profile-setup';
        }

        // 프로필 완료됐는데 /profile-setup 접근 → /home
        if (isAuthenticated && profileComplete && location == '/profile-setup') {
          return '/home';
        }

        //admin이 아니라면 home으로 라우팅
        if (location == '/admin' && !authProvider.isAdmin) {
          return '/home';
        }

        return null;
      },

      routes: [
        GoRoute(
          path: '/profile-setup',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/profile-edit',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ProfileSetupScreen(isEditMode: true),
        ),

        // 성분 상세
        GoRoute(
          path: '/ingredients/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return IngredientDetailScreen(ingredientId: id);
          },
        ),

        // 커뮤니티 — 글쓰기 (전체 화면)
        GoRoute(
          path: '/community/write',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final editPost = state.extra as PostModel?;
            return PostWriteScreen(editPost: editPost);
          },
        ),
        // 커뮤니티 — 상세 (전체 화면)
        GoRoute(
          path: '/community/:postId',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final postId = int.parse(state.pathParameters['postId']!);
            return PostDetailScreen(postId: postId);
          },
        ),
        // 제품 상세
        GoRoute(
          path: '/products/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final product = state.extra as ProductModel;
            return ProductDetailScreen(product: product);
          },
        ),

        //관리자 페이지
        GoRoute(
          path: '/admin',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const AdminScreen(),
        ),

        // ShellRoute (하단바 고정)
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            final String location = state.uri.toString();

            int currentIndex = 0;
            if (location.startsWith('/community')) currentIndex = 1;
            else if (location.startsWith('/search')) currentIndex = 2;
            else if (location.startsWith('/skin-diary')) currentIndex = 3;
            else if (location.startsWith('/mypage')) currentIndex = 4;

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: MainTopNavBar(isHome: location == '/home'),
              body: child,
              bottomNavigationBar: MainBottomNavBar(
                currentIndex: currentIndex,
              ),
            );
          },
          routes: [
            GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen()),

            GoRoute(
                path: '/community',
                builder: (context, state) => const PostListScreen()),

            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),

            GoRoute(
                path: '/skin-diary',
                builder: (context, state) => const SkinDiaryScreen()),

            GoRoute(
                path: '/mypage',
                builder: (context, state) => const MypageScreen()),
          ],
        ),
      ],
    );
  }
}