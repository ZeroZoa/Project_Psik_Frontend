import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../providers/community_provider.dart';
import '../widgets/post_card.dart';

/// HOT / NEW / POPULAR 전체 목록 화면 (무한 스크롤)
/// [type]: 'hot' | 'new' | 'popular'
class PostListAllScreen extends StatefulWidget {
  final String type;
  const PostListAllScreen({super.key, required this.type});

  @override
  State<PostListAllScreen> createState() => _PostListAllScreenState();
}

class _PostListAllScreenState extends State<PostListAllScreen> {
  final ScrollController _scrollController = ScrollController();

  String get _title => switch (widget.type) {
    'hot' => 'HOT 게시글',
    'popular' => '많이 본 게시글',
    _ => '새로운 게시글',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchAllPosts(widget.type, refresh: true);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<CommunityProvider>().fetchAllPosts(widget.type);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textTitle, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(_title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textTitle)),
        centerTitle: true,
      ),
      body: provider.isAllPostsLoading && provider.allPosts.isEmpty
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
        onRefresh: () =>
            provider.fetchAllPosts(widget.type, refresh: true),
        color: AppColors.primary,
        child: provider.allPosts.isEmpty
            ? ListView(children: const [
          SizedBox(height: 200),
          Center(child: Text('게시글이 없습니다.')),
        ])
            : ListView.builder(
          controller: _scrollController,
          itemCount: provider.allPosts.length +
              (provider.hasMoreAllPosts ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.allPosts.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
              );
            }
            final post = provider.allPosts[index];
            return PostCard(
              post: post,
              onTap: () =>
                  context.push('/community/${post.postId}'),
            );
          },
        ),
      ),
    );
  }
}