import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/login_modal.dart';
import '../providers/community_provider.dart';
import '../widgets/post_card.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().refreshPosts();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<CommunityProvider>().loadMorePosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildSortTabs(provider),
          Expanded(
            child: provider.isLoading && provider.posts.isEmpty
                ? const Center(
                child:
                CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
              onRefresh: () => provider.refreshPosts(),
              color: AppColors.primary,
              child: provider.posts.isEmpty
                  ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('게시글이 없습니다.')),
                ],
              )
                  : ListView.builder(
                controller: _scrollController,
                itemCount: provider.posts.length +
                    (provider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == provider.posts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    );
                  }
                  final post = provider.posts[index];
                  return PostCard(
                    post: post,
                    onTap: () async {
                      await context.push('/community/${post.postId}');
                      if (context.mounted) {
                        context.read<CommunityProvider>().refreshPosts();
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      //글쓰기 버튼 — 비로그인 시 로그인 모달
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!await requireLogin(context)) return;
          if (context.mounted) context.push('/community/write');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildSortTabs(CommunityProvider provider) {
    final tabs = [
      ('latest', '최신순'),
      ('likes', '인기순'),
      ('views', '조회순'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: tabs
            .map((tab) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => provider.changeSortAndRefresh(tab.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: provider.currentSort == tab.$1
                    ? AppColors.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: provider.currentSort == tab.$1
                      ? Colors.transparent
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                tab.$2,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: provider.currentSort == tab.$1
                      ? Colors.white
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ))
            .toList(),
      ),
    );
  }
}