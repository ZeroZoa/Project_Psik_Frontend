import 'package:flutter/material.dart';
import '../../../../common/theme/app_colors.dart';
import '../../data/models/comment_model.dart';

class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final bool isReply;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    this.isReply = false,
    required this.onLike,
    required this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: isReply ? 40 : 16,
        right: 16,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: isReply ? Colors.grey.shade50 : Colors.white,
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.surface,
                backgroundImage: comment.authorProfileImageUrl != null
                    ? NetworkImage(comment.authorProfileImageUrl!)
                    : null,
                child: comment.authorProfileImageUrl == null
                    ? const Icon(Icons.person, size: 12, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(comment.authorNickname,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child:
                  Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.content,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textBody, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      comment.likedByMe
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 14,
                      color:
                      comment.likedByMe ? AppColors.error : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text('${comment.likeCount}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (!isReply) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: onReply,
                  child: Text('답글',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}