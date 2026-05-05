import 'package:flutter/material.dart';

import '../../../../../common/theme/app_colors.dart';

/// 게시글 이미지 갤러리 위젯 — PageView + 하단 인디케이터
/// - [imageUrls] 1개면 인디케이터 미표시
/// - 내부적으로 현재 페이지 인덱스 상태 관리
/// - [PostDetailScreen] 본문 이미지 섹션에서 사용
class PostImageGallery extends StatefulWidget {
  final List<String> imageUrls;

  const PostImageGallery({super.key, required this.imageUrls});

  @override
  State<PostImageGallery> createState() => _PostImageGalleryState();
}

/// [PostImageGallery]의 State — 현재 페이지 인덱스(_currentIndex) 관리
class _PostImageGalleryState extends State<PostImageGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
                  (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _currentIndex == index ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _currentIndex == index
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
}