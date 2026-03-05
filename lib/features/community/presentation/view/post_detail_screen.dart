import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../providers/community_provider.dart';
import '../widgets/comment_item.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  int? _replyToCommentId;
  String? _replyToNickname;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CommunityProvider>();
      provider.fetchPost(widget.postId);
      provider.fetchComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _setReplyTarget(int commentId, String nickname) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToNickname = nickname;
    });
    _commentController.clear();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToNickname = null;
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<CommunityProvider>();
    await provider.createComment(widget.postId,
        content: text, parentId: _replyToCommentId);
    _commentController.clear();
    _cancelReply();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final post = provider.currentPost;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop()),
        title: const Text('게시글'),
        actions: [
          if (post != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push('/community/write', extra: post);
                } else if (value == 'delete') {
                  await provider.deletePost(post.postId);
                  if (context.mounted) context.pop();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('수정')),
                const PopupMenuItem(value: 'delete', child: Text('삭제')),
              ],
            ),
        ],
      ),
      body: provider.isDetailLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : post == null
          ? const Center(child: Text('게시글을 불러올 수 없습니다.'))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surface,
                        backgroundImage:
                        post.authorProfileImageUrl != null
                            ? NetworkImage(
                            post.authorProfileImageUrl!)
                            : null,
                        child: post.authorProfileImageUrl == null
                            ? const Icon(Icons.person,
                            size: 18, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(post.authorNickname,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(
                              DateFormat('M.d HH:mm')
                                  .format(post.createdAt),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 제목
                  Text(post.title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textTitle)),
                  const SizedBox(height: 16),

                  // 이미지 갤러리
                  if (post.imageUrls.isNotEmpty) ...[
                    _buildImageGallery(post.imageUrls),
                    const SizedBox(height: 16),
                  ],

                  // 본문
                  Text(post.content ?? '',
                      style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textBody,
                          height: 1.6)),
                  const SizedBox(height: 24),

                  // 좋아요 + 조회수
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            provider.togglePostLike(post.postId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: post.likedByMe
                                ? AppColors.error
                                .withValues(alpha: 0.1)
                                : AppColors.surface,
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                post.likedByMe
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: post.likedByMe
                                    ? AppColors.error
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text('${post.likeCount}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: post.likedByMe
                                          ? AppColors.error
                                          : Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('조회 ${post.viewCount}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 8),

                  // 댓글
                  Text('댓글 ${post.commentCount}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (provider.isCommentsLoading)
                    const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                  else
                    ...provider.comments.expand((root) => [
                      CommentItem(
                        comment: root,
                        onLike: () =>
                            provider.toggleCommentLike(
                                widget.postId,
                                root.commentId),
                        onReply: () => _setReplyTarget(
                            root.commentId,
                            root.authorNickname),
                      ),
                      ...root.children.map((child) =>
                          CommentItem(
                            comment: child,
                            isReply: true,
                            onLike: () =>
                                provider.toggleCommentLike(
                                    widget.postId,
                                    child.commentId),
                            onReply: () {},
                          )),
                    ]),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  /// 이미지 갤러리 (PageView + 인디케이터)
  Widget _buildImageGallery(List<String> imageUrls) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: imageUrls.length,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surface,
                    child: const Center(
                        child: Icon(Icons.broken_image,
                            size: 48, color: Colors.grey)),
                  ),
                ),
              );
            },
          ),
        ),
        if (imageUrls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageUrls.length,
                  (index) => Container(
                width: _currentImageIndex == index ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _currentImageIndex == index
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToNickname != null)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Text('$_replyToNickname님에게 답글',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textBody)),
                  const Spacer(),
                  GestureDetector(
                      onTap: _cancelReply,
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.grey)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: _replyToNickname != null
                        ? '답글을 입력하세요...'
                        : '댓글을 입력하세요...',
                    hintStyle: const TextStyle(
                        fontSize: 14, color: AppColors.textSub1),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submitComment,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child:
                  const Icon(Icons.send, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}