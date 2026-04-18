import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../../common/widgets/login_modal.dart';
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

  //전체 리프레쉬
  Future<void> _refresh() async {
    final provider = context.read<CommunityProvider>();
    await provider.fetchPost(widget.postId);
    await provider.fetchComments(widget.postId);
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
    if (!await requireLogin(context)) return;
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<CommunityProvider>();
    await provider.createComment(widget.postId,
        content: text, parentId: _replyToCommentId);
    _commentController.clear();
    _cancelReply();
  }

  void _showPostOptions(BuildContext context, CommunityProvider provider, post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 수정 버튼
              // 수정 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/community/write', extra: post);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('수정하기',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.textBody,
                    backgroundColor: Colors.grey.shade100,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 삭제 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await provider.deletePost(post.postId);
                    if (context.mounted) context.pop();
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('삭제하기',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    backgroundColor: AppColors.error.withValues(alpha: 0.08),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showPostOptions(context, provider, post),
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
      child: RefreshIndicator(
        onRefresh: _refresh,
          color: AppColors.primary,
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
                          onTap: () async {
                            if (!await requireLogin(context)) return;
                            provider.togglePostLike(post.postId);
                          },
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
                          onLike: () async {
                            if (!await requireLogin(context)) return; // [추가]
                            provider.toggleCommentLike(widget.postId, root.commentId);
                          },
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