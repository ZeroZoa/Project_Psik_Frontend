import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../widgets/post_image_section.dart';
import '../../data/models/post_model.dart';
import '../providers/community_provider.dart';

/// 게시글 작성/수정 화면 진입점
/// - [editPost] null → 작성 모드, non-null → 수정 모드
/// - 수정 모드에서 기존 이미지는 URL이라 로컬 path 없음 → 새 이미지로 교체됨
/// - Provider는 [PostListScreen]의 전역 [CommunityProvider]를 그대로 사용
class PostWriteScreen extends StatefulWidget {
  final PostModel? editPost;
  const PostWriteScreen({super.key, this.editPost});

  @override
  State<PostWriteScreen> createState() => _PostWriteScreenState();
}

/// [PostWriteScreen]의 State — 제목/내용/이미지 경로 상태 및 제출 로직 관리
/// 관리 상태: 제목 컨트롤러, 내용 컨트롤러, 로컬 이미지 경로 목록(_imagePaths)
class _PostWriteScreenState extends State<PostWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<XFile> _imageFiles = [];
  bool _isSubmitting = false;

  bool get _isEdit => widget.editPost != null;
  static const int _maxImages = 5;

  /// 수정 모드 진입 시 기존 제목/내용을 컨트롤러에 바인딩
  /// 기존 이미지 URL은 로컬 path가 아니므로 _imagePaths에 포함하지 않음
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

  /// 갤러리에서 이미지 다중 선택 — 남은 슬롯 수만큼만 추가
  /// 이미 [_maxImages]에 도달한 경우 스낵바 안내 후 조기 반환
  Future<void> _pickImages() async {
    if (_imageFiles.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지는 최대 5장까지 첨부할 수 있습니다.')),
      );
      return;
    }

    final picker = ImagePicker();
    final remaining = _maxImages - _imageFiles.length;

    final picked = await picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (picked.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(picked.take(remaining));
      });
    }
  }

  /// [index] 위치의 이미지를 _imagePaths에서 제거
  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  /// 제목/내용 유효성 검사 후 게시글 생성/수정 API 호출
  /// - 작성 모드: [CommunityProvider.createPost]
  /// - 수정 모드: [CommunityProvider.updatePost]
  /// - 성공 시 화면 pop, 실패 시 에러 스낵바
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
          imageFiles: _imageFiles.isEmpty ? null : _imageFiles,
        );
      } else {
        await provider.createPost(
          title: title,
          content: content,
          imageFiles: _imageFiles.isEmpty ? null : _imageFiles,
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
            if (_imageFiles.isNotEmpty || !_isEdit)
              PostImageSection(
                imageFiles: _imageFiles,
                maxImages: _maxImages,
                onAdd: _pickImages,
                onRemove: _removeImage,
              ),
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
}