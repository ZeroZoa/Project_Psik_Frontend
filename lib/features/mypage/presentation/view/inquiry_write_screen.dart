import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../data/repositories/inquiry_repository.dart';
import '../providers/inquiry_provider.dart';

/// 문의 작성 화면 (사용자)
/// - Provider는 화면 진입 시 자체 생성 — post_write_screen 패턴 동일
class InquiryWriteScreen extends StatelessWidget {
  const InquiryWriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          InquiryProvider(context.read<InquiryRepository>()),
      child: const _InquiryWriteView(),
    );
  }
}

class _InquiryWriteView extends StatefulWidget {
  const _InquiryWriteView();

  @override
  State<_InquiryWriteView> createState() => _InquiryWriteViewState();
}

class _InquiryWriteViewState extends State<_InquiryWriteView> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final success = await context.read<InquiryProvider>().submitInquiry(
        title: title,
        content: content,
      );
      if (!mounted) return;
      if (success) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('문의 등록에 실패했습니다.'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('문의 작성'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('완료',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              maxLength: 100,
            ),
            Divider(color: Colors.grey.shade200),
            Expanded(
              child: TextField(
                controller: _contentController,
                style: const TextStyle(fontSize: 15, height: 1.6),
                decoration: const InputDecoration(
                  hintText: '문의 내용을 입력하세요',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}