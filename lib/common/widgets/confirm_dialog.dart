import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 파괴적 액션(삭제/연결 해제 등) 전 확인 다이얼로그.
/// 사용자가 확인을 누르면 true, 취소하거나 다이얼로그 밖을 탭하면 false를 반환한다.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = '삭제',
  String cancelLabel = '취소',
  Color confirmColor = AppColors.error,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel,
              style: TextStyle(color: Colors.grey.shade600)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel,
              style: TextStyle(
                  color: confirmColor, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
  return result ?? false;
}
