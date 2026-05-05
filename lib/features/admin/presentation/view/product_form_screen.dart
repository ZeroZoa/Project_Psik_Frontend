import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../common/theme/app_colors.dart';
import '../../../home/data/models/product_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../providers/admin_provider.dart';

/// 제품 생성/수정 폼 화면 진입점
/// - [product] null → 생성 모드, non-null → 수정 모드
/// - Provider는 [AdminScreen]에서 [ChangeNotifierProvider.value]로 주입받음
/// - 제출: [AdminProvider.createProduct] / [AdminProvider.updateProduct]
class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

/// [ProductFormScreen]의 State — 폼 입력값 및 생성/수정 로직 관리
/// 관리 상태: 제품명, 브랜드, 가격, 설명, 구매링크, 이미지URL (컨트롤러 6개)
class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _linkController;

  XFile? _selectedImage;
  String? _currentImageUrl; // 수정 모드에서 기존 이미지 URL
  bool _isUploadingImage = false;
  bool _isLoading = false;

  /// 수정 모드 진입 시 기존 제품 데이터를 각 컨트롤러에 바인딩
  /// 생성 모드에서는 빈 문자열로 초기화
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _priceController =
        TextEditingController(text: p?.price?.toString() ?? '');
    _descriptionController =
        TextEditingController(text: p?.description ?? '');
    _linkController = TextEditingController(text: p?.link ?? '');
    _currentImageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  /// 폼 유효성 검사 후 생성/수정 API 호출
  /// - 빈 문자열 optional 필드는 null로 변환 후 전달
  /// - 성공 시 화면 pop + 스낵바, 실패 시 에러 스낵바
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = context.read<AdminProvider>();
    final isEdit = widget.product != null;
    final price = int.tryParse(_priceController.text.trim());

    String? brandVal = _brandController.text.trim().isEmpty
        ? null : _brandController.text.trim();
    String? descVal = _descriptionController.text.trim().isEmpty
        ? null : _descriptionController.text.trim();
    String? linkVal = _linkController.text.trim().isEmpty
        ? null : _linkController.text.trim();
    String? imageVal = _currentImageUrl;

    if (_selectedImage != null) {
      setState(() => _isUploadingImage = true);
      try {
        imageVal = await context
            .read<AdminRepository>()
            .uploadProductImage(_selectedImage!);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('이미지 업로드에 실패했습니다.'),
          backgroundColor: AppColors.error,
        ));
        return;
      }
      setState(() => _isUploadingImage = false);
    }

    final success = isEdit
        ? await provider.updateProduct(
      id: widget.product!.id,
      name: _nameController.text.trim(),
      brand: brandVal,
      price: price,
      description: descVal,
      link: linkVal,
      imageUrl: imageVal,
    )
        : await provider.createProduct(
      name: _nameController.text.trim(),
      brand: brandVal,
      price: price,
      description: descVal,
      link: linkVal,
      imageUrl: imageVal,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEdit ? '수정되었습니다.' : '생성되었습니다.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('저장에 실패했습니다.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.product == null ? '제품 추가' : '제품 수정',
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textTitle),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field('제품명 *', _nameController, '예) 나이아신아마이드 10% + HA',
                validator: (v) => v == null || v.trim().isEmpty
                    ? '제품명을 입력해주세요.'
                    : null),
            const SizedBox(height: 16),
            _field('브랜드', _brandController, '예) The Ordinary'),
            const SizedBox(height: 16),
            _field('가격', _priceController, '예) 15000',
                inputType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly]),
            const SizedBox(height: 16),
            _field('제품 설명', _descriptionController,
                '제품에 대한 간단한 설명',
                maxLines: 3),
            const SizedBox(height: 16),
            _field('구매 링크', _linkController, 'https://...'),
            const SizedBox(height: 16),
            _buildImagePicker(),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : Text(
                  widget.product == null ? '추가하기' : '수정하기',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  //Product 이미지 피커 위젯
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('제품 이미지',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textTitle)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 80,
            );
            if (picked != null) {
              setState(() {
                _selectedImage = picked;
                _currentImageUrl = null;
              });
            }
          },
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: _isUploadingImage
                ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
                : _selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: kIsWeb
                  ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                  : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
            )
                : _currentImageUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                _currentImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 36, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('사진을 선택하세요',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ),
      ],
    );
  }


  /// 폼 필드 공통 위젯 헬퍼 — 레이블 + TextFormField
  /// enabled/focused/error 테두리 스타일 통일
  /// [validator], [inputType], [formatters], [maxLines] 옵션 지원
  Widget _field(
      String label,
      TextEditingController controller,
      String hint, {
        String? Function(String?)? validator,
        TextInputType? inputType,
        List<TextInputFormatter>? formatters,
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textTitle)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          inputFormatters: formatters,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}