import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../common/theme/app_colors.dart';
import '../../data/models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTimeAgo(post.createdAt);
    final bool hasImage = post.imageUrls.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.surface,
                        backgroundImage: post.authorProfileImageUrl != null
                            ? NetworkImage(post.authorProfileImageUrl!)
                            : null,
                        child: post.authorProfileImageUrl == null
                            ? const Icon(Icons.person,
                            size: 12, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(post.authorNickname,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(timeAgo,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 제목
                  Text(
                    post.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textTitle),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // 좋아요, 댓글, 조회수
                  Row(
                    children: [
                      _statIcon(
                        post.likedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        '${post.likeCount}',
                        post.likedByMe ? AppColors.error : Colors.grey,
                      ),
                      const SizedBox(width: 14),
                      _statIcon(Icons.chat_bubble_outline,
                          '${post.commentCount}', Colors.grey),
                      const SizedBox(width: 14),
                      _statIcon(Icons.remove_red_eye_outlined,
                          '${post.viewCount}', Colors.grey),
                    ],
                  ),
                ],
              ),
            ),

            // 썸네일 이미지 (있으면 표시)
            if (hasImage) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.imageUrls.first,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.surface,
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey, size: 24),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statIcon(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('M.d').format(dateTime);
  }
}