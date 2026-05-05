import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../common/theme/app_colors.dart';

/// 게시글 이미지 첨부 영역 위젯
/// - 이미지 추가 버튼 + 선택된 이미지 가로 스크롤 미리보기
/// - [maxImages] 도달 시 추가 버튼 자동 숨김
/// - [imageFiles] XFile 리스트 — Web/Mobile 렌더링 분기 내부 처리
/// - [onAdd] 추가 버튼 탭 시 호출 (이미지 피커 로직은 [PostWriteScreen]에서 관리)
/// - [onRemove] 개별 이미지 삭제 버튼 탭 시 호출
/// - [PostWriteScreen] 글쓰기/수정 폼에서 사용
class PostImageSection extends StatelessWidget {
  final List<XFile> imageFiles;
  final int maxImages;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const PostImageSection({
    super.key,
    required this.imageFiles,
    required this.maxImages,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 90,
      child: Row(
        children: [
          // 이미지 추가 버튼 — maxImages 미달 시에만 표시
          if (imageFiles.length < maxImages)
            GestureDetector(
              onTap: onAdd,
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
                    Text(
                      '${imageFiles.length}/$maxImages',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

          // 선택된 이미지 가로 스크롤 미리보기
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imageFiles.length,
              itemBuilder: (context, index) {
                final xfile = imageFiles[index];
                return SizedBox(
                  width: 88,
                  height: 80,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          // Web: blob URL로 Image.network / Mobile: File 경로로 Image.file
                          child: kIsWeb
                              ? Image.network(xfile.path, fit: BoxFit.cover)
                              : Image.file(File(xfile.path), fit: BoxFit.cover),
                        ),
                      ),
                      // 삭제 버튼
                      Positioned(
                        top: -6,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => onRemove(index),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}