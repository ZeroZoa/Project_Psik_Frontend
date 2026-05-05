import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:psik_frontend/features/diary/presentation/view/skin_diary_screen.dart';

import '../../features/admin/presentation/view/admin_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/view/profile_setup_screen.dart';
import '../../features/community/presentation/view/post_list_all_screen.dart';
import '../../features/home/data/models/product_model.dart';
import '../../features/home/presentation/view/product_detail_screen.dart';
import '../../features/mypage/presentation/view/inquiry_list_screen.dart';
import '../../features/mypage/presentation/view/inquiry_write_screen.dart';
import '../../features/mypage/presentation/view/mypage_screen.dart';

import '../../common/widgets/main_bottom_nav_bar.dart';
import '../../common/widgets/main_top_nav_bar.dart';

import '../../features/home/presentation/view/home_screen.dart';
import '../../features/home/presentation/view/ingredient_detail_screen.dart';
import '../../features/community/presentation/view/post_home_screen.dart';
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
        if (isAuthenticated &&
            !profileComplete &&
            location != '/profile-setup' &&
            !authProvider.isAdmin) {
          return '/profile-setup';
        }

        // 프로필 완료됐는데 /profile-setup 접근 → /home
        if (isAuthenticated && profileComplete && location == '/profile-setup') {
          return '/home';
        }

        // admin이 아니라면 /admin 접근 차단
        if (location == '/admin' && !authProvider.isAdmin) {
          return '/home';
        }

        return null;
      },

      routes: [
        // ──────────────────────────────────────────────────────────────
        // [인증] 프로필 설정 / 수정
        // 네비게이션 바 없는 전체 화면
        // ──────────────────────────────────────────────────────────────
        GoRoute(
          path: '/profile-setup',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/profile-edit',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) =>
              const ProfileSetupScreen(isEditMode: true),
        ),

        // ──────────────────────────────────────────────────────────────
        // [홈] 성분 상세
        // 네비게이션 바 없는 전체 화면
        // ──────────────────────────────────────────────────────────────
        GoRoute(
          path: '/ingredients/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) return const Scaffold(body: Center(child: Text('잘못된 접근입니다.')));
            return IngredientDetailScreen(ingredientId: id);
          },
        ),

        // ──────────────────────────────────────────────────────────────
        // [홈] 제품 상세
        // 네비게이션 바 없는 전체 화면
        // ──────────────────────────────────────────────────────────────
        GoRoute(
          path: '/products/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final product = state.extra as ProductModel?;
            if (product == null) {
              return const Scaffold(
                body: Center(child: Text('제품 정보를 불러올 수 없습니다.')),
              );
            }
            return ProductDetailScreen(product: product);
          },
        ),

        // ──────────────────────────────────────────────────────────────
        // [커뮤니티] 글쓰기 / 글 상세 → /community sub-route로 이동
        // (최상위에 두면 ShellRoute의 hot/new/popular보다 먼저 매칭됨)
        // ──────────────────────────────────────────────────────────────

        // ──────────────────────────────────────────────────────────────
        // [관리자] 관리자 페이지
        // isAdmin 검사는 redirect에서 처리
        // 네비게이션 바 없는 전체 화면
        // ──────────────────────────────────────────────────────────────
        GoRoute(
          path: '/admin',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const AdminScreen(),
        ),

        GoRoute(
          path: '/inquiry',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const InquiryListScreen(),
        ),
        GoRoute(
          path: '/inquiry/write',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const InquiryWriteScreen(),
        ),

        // ──────────────────────────────────────────────────────────────
        // [ShellRoute] 하단 네비게이션 바 + 상단 앱바 고정
        // 하단 탭: 홈(0) / 커뮤니티(1) / 검색(2) / 피부일기(3) / 마이페이지(4)
        // 이 안에 포함된 라우트는 네비게이션 바가 항상 표시됨
        // ──────────────────────────────────────────────────────────────
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
            // 홈
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),

            // 커뮤니티 홈 + HOT/NEW/POPULAR 전체 목록 + 글쓰기 + 글 상세
            // 주의: write, hot, new, popular는 반드시 :postId 보다 먼저 선언
            //       parentNavigatorKey: rootNavigatorKey → 네비게이션 바 없는 전체 화면
            GoRoute(
              path: '/community',
              builder: (context, state) => const PostHomeScreen(),
              routes: [
                GoRoute(
                  path: 'write',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final editPost = state.extra as PostModel?;
                    return PostWriteScreen(editPost: editPost);
                  },
                ),
                GoRoute(
                  path: 'hot',
                  builder: (context, state) =>
                      const PostListAllScreen(type: 'hot'),
                ),
                GoRoute(
                  path: 'new',
                  builder: (context, state) =>
                      const PostListAllScreen(type: 'new'),
                ),
                GoRoute(
                  path: 'popular',
                  builder: (context, state) =>
                      const PostListAllScreen(type: 'popular'),
                ),
                GoRoute(
                  path: ':postId',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final postId = int.tryParse(state.pathParameters['postId'] ?? '');
                    if (postId == null) return const Scaffold(body: Center(child: Text('잘못된 접근입니다.')));
                    return PostDetailScreen(postId: postId);
                  },
                ),
              ],
            ),

            // 검색
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),

            // 피부 다이어리
            GoRoute(
              path: '/skin-diary',
              builder: (context, state) => const SkinDiaryScreen(),
            ),

            // 마이페이지
            GoRoute(
              path: '/mypage',
              builder: (context, state) => const MypageScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
