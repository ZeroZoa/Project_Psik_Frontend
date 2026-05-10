import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/login_modal.dart';
import '../providers/community_provider.dart';
import '../widgets/post_home_section.dart';

/// 커뮤니티 홈 화면 (HOT / NEW / POPULAR 섹션)
/// 각 섹션 더보기 → PostListAllScreen(HOT, NEW, POPULAR)으로 이동
class PostHomeScreen extends StatefulWidget {
  const PostHomeScreen({super.key});

  @override
  State<PostHomeScreen> createState() => _PostHomeScreenState();
}

class _PostHomeScreenState extends State<PostHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchHomePosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: provider.isHomeLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
        onRefresh: () => provider.fetchHomePosts(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(42, 20, 42, 12),
          children: [
            PostHomeSection(title: '새로운 게시글', type: 'new', posts: provider.newPosts),
            PostHomeSection(title: 'HOT 게시글', type: 'hot', posts: provider.hotPosts),
            PostHomeSection(title: '많이 본 게시글', type: 'popular', posts: provider.popularPosts),
            const SizedBox(height: 8),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!await requireLogin(context)) return;
          if (context.mounted) context.push('/community/write');
        },
        backgroundColor: AppColors.primary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        hoverColor: Colors.black.withValues(alpha: 0.12),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}