import 'package:flutter/material.dart';

import '../../../../../common/theme/app_colors.dart';

/// 게시글 하단 댓글/대댓글 입력 위젯
/// - [replyToNickname] non-null이면 대댓글 모드 — 대상 닉네임 배너 표시
/// - [controller] 입력 텍스트 컨트롤러 ([PostDetailScreen]에서 생명주기 관리)
/// - [onSubmit] 전송 버튼 탭 시 호출
/// - [onCancelReply] 대댓글 취소 버튼 탭 시 호출
/// - [PostDetailScreen] 하단 고정 영역에서 사용
class PostCommentInput extends StatelessWidget {
  final TextEditingController controller;
  final String? replyToNickname;
  final VoidCallback onSubmit;
  final VoidCallback onCancelReply;

  const PostCommentInput({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.onCancelReply,
    this.replyToNickname,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 대댓글 대상 배너
          if (replyToNickname != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '$replyToNickname님에게 답글',
                    style: const TextStyle(fontSize: 13, color: AppColors.textBody),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          // 입력창 + 전송 버튼
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: replyToNickname != null ? '답글을 입력하세요...' : '댓글을 입력하세요...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSub1),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onSubmit,
                  customBorder: const CircleBorder(),
                  hoverColor: Colors.black.withValues(alpha: 0.12),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.send, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}