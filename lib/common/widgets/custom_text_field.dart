import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmitted;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint = '',
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onSubmitted,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.textTitle,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          style: const TextStyle(
            color: AppColors.textBody,
            fontSize: 16,
          ),
          cursorColor: AppColors.primary,
          onFieldSubmitted: (_) {
            if (widget.onSubmitted != null) widget.onSubmitted!();
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: AppColors.textSub1,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

            //라운딩 16 적용
            border: _border(AppColors.inputBorder),
            enabledBorder: _border(AppColors.inputBorder),
            focusedBorder: _border(AppColors.primary, width: 2.0),
            errorBorder: _border(AppColors.error),
            focusedErrorBorder: _border(AppColors.error, width: 2.0),

            suffixIcon: widget.isPassword
                ? IconButton(
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
              icon: Icon(
                _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSub1,
              ),
            )
                : null,
          ),
        ),
      ],
    );
  }

  // [수정] 테두리 라운딩 값을 12 -> 16으로 변경
  OutlineInputBorder _border(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}