import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../providers/community_provider.dart';
import 'post_card.dart';

/// 커뮤니티 홈 섹션 (HOT / NEW / POPULAR)
/// - 타이틀 + 더보기 버튼 → 카드 밖 Row
/// - 게시글 목록 → 카드 안 (ingredient_info_card 동일 디자인)
class PostHomeSection extends StatelessWidget {
  final String title;
  final String type;
  final List<PostModel> posts;

  const PostHomeSection({
    super.key,
    required this.title,
    required this.type,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 타이틀 + 더보기 (카드 밖) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textTitle,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/community/$type'),
                child: Row(
                  children: const [
                    Text(
                      '더보기',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSub2,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      size: 15,
                      color: AppColors.textSub2,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── 카드 ──
          Container(
            padding: const EdgeInsets.all(8),
            clipBehavior: Clip.hardEdge,  // ← 추가 (내용이 둥근 모서리 밖으로 안 나옴)
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.inputBorder.withValues(alpha: 0.6),
              ),
            ),
            child: posts.isEmpty
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '게시글이 없습니다.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSub2),
                ),
              ),
            )
                : Column(
              children: List.generate(posts.length, (index) {
                final post = posts[index];
                final isLast = index == posts.length - 1;
                return PostCard(
                  post: post,
                  isLast: isLast,  // ← 마지막 카드 border 제거
                  onTap: () async {
                    await context.push('/community/${post.postId}');
                    if (context.mounted) {
                      context.read<CommunityProvider>().fetchHomePosts();
                    }
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}