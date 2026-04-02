import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../common/theme/app_colors.dart';
import '../../../home/data/models/product_model.dart';
import '../providers/admin_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _linkController;
  late final TextEditingController _imageUrlController;

  bool _isLoading = false;

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
    _imageUrlController =
        TextEditingController(text: p?.imageUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

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
    String? imageVal = _imageUrlController.text.trim().isEmpty
        ? null : _imageUrlController.text.trim();

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
            _field('이미지 URL', _imageUrlController, 'https://...'),
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