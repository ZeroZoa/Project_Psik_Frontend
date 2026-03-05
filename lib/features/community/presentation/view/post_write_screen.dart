import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../providers/community_provider.dart';

class PostWriteScreen extends StatefulWidget {
  final PostModel? editPost;
  const PostWriteScreen({super.key, this.editPost});

  @override
  State<PostWriteScreen> createState() => _PostWriteScreenState();
}

class _PostWriteScreenState extends State<PostWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<String> _imagePaths = []; // 로컬 파일 경로
  bool _isSubmitting = false;

  bool get _isEdit => widget.editPost != null;
  static const int _maxImages = 5;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _titleController.text = widget.editPost!.title;
      _contentController.text = widget.editPost!.content ?? '';
      // 수정 시 기존 이미지는 URL이라 로컬 path가 아님
      // → 수정하면 새로 선택한 이미지로 교체됨 (UX에서 안내 필요)
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_imagePaths.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지는 최대 5장까지 첨부할 수 있습니다.')),
      );
      return;
    }

    final picker = ImagePicker();
    final remaining = _maxImages - _imagePaths.length;

    final picked = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (picked.isNotEmpty) {
      setState(() {
        _imagePaths.addAll(
          picked.take(remaining).map((xfile) => xfile.path),
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
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
      final provider = context.read<CommunityProvider>();

      if (_isEdit) {
        await provider.updatePost(
          widget.editPost!.postId,
          title: title,
          content: content,
          imagePaths: _imagePaths.isEmpty ? null : _imagePaths,
        );
      } else {
        await provider.createPost(
          title: title,
          content: content,
          imagePaths: _imagePaths.isEmpty ? null : _imagePaths,
        );
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('저장 실패: $e'),
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
            onPressed: () => context.pop()),
        title: Text(_isEdit ? '게시글 수정' : '글쓰기'),
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
            // 제목
            TextField(
              controller: _titleController,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
              maxLength: 100,
            ),
            Divider(color: Colors.grey.shade200),

            // 이미지 프리뷰
            if (_imagePaths.isNotEmpty || !_isEdit) _buildImageSection(),

            // 본문
            Expanded(
              child: TextField(
                controller: _contentController,
                style: const TextStyle(fontSize: 15, height: 1.6),
                decoration: const InputDecoration(
                  hintText: '내용을 입력하세요',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
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

  Widget _buildImageSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 90,
      child: Row(
        children: [
          // 이미지 추가 버튼
          if (_imagePaths.length < _maxImages)
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined,
                        color: Colors.grey, size: 24),
                    const SizedBox(height: 4),
                    Text('${_imagePaths.length}/$_maxImages',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),

          // 선택된 이미지 프리뷰
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imagePaths.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_imagePaths[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}