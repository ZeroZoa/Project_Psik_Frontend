import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SocialLoginButton extends StatelessWidget {
  final String assetPath;
  final Color backgroundColor;
  final VoidCallback onTap;
  final double padding;
  final bool hasBorder;

  const SocialLoginButton({
    required this.assetPath,
    required this.backgroundColor,
    required this.onTap,
    this.padding = 12.0,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(50),
          // 테두리 조건부 적용 (구글 버튼용)
          border: hasBorder
              ? Border.all(color: Colors.grey.shade300, width: 1)
              : null,
          boxShadow: [
            // 살짝 그림자 주면 더 버튼 같습니다 (선택 사항)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(padding),
        child: SvgPicture.asset(
          assetPath,
        ),
      ),
    );
  }
}