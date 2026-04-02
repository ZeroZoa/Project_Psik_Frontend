import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../common/theme/app_colors.dart';
import '../../../auth/domain/enums/skin_concern.dart';
import '../../../home/data/repositories/cosmetics_repository.dart';
import '../providers/admin_provider.dart';

class IngredientFormScreen extends StatefulWidget {
  final int? ingredientId;

  const IngredientFormScreen({super.key, this.ingredientId});

  @override
  State<IngredientFormScreen> createState() => _IngredientFormScreenState();
}

class _IngredientFormScreenState extends State<IngredientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _effectSummaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _effectController = TextEditingController();
  final _cautionController = TextEditingController();

  String _selectedType = 'GENERAL';
  final List<String> _effects = [];
  final List<String> _cautions = [];
  final Set<SkinConcern> _selectedConcerns = {};

  bool _isLoading = false;
  bool _isInitLoading = false;

  final List<Map<String, String>> _types = [
    {'value': 'GENERAL', 'label': '일반/화장품'},
    {'value': 'OTC', 'label': '일반의약품/약국'},
    {'value': 'PRESCRIPTION', 'label': '전문의약품/병원'},
    {'value': 'OVERSEAS', 'label': '해외직구/직수입'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ingredientId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isInitLoading = true);
    try {
      final repo = context.read<CosmeticsRepository>();
      final detail = await repo.getIngredientDetail(widget.ingredientId!);
      _nameController.text = detail.name;
      _effectSummaryController.text = detail.effectSummary;
      _descriptionController.text = detail.description;
      _selectedType = _typeFromTitle(detail.typeTitle);
      _effects.addAll(detail.effects);
      _cautions.addAll(detail.cautions);
      for (final c in detail.skinConcerns) {
        try { _selectedConcerns.add(SkinConcern.values.byName(c)); } catch (_) {}
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')));
    } finally {
      if (mounted) setState(() => _isInitLoading = false);
    }
  }

  String _typeFromTitle(String title) {
    switch (title) {
      case '일반/화장품': return 'GENERAL';
      case '일반의약품/약국': return 'OTC';
      case '전문의약품/병원': return 'PRESCRIPTION';
      case '해외직구/직수입': return 'OVERSEAS';
      default: return 'GENERAL';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _effectSummaryController.dispose();
    _descriptionController.dispose();
    _effectController.dispose();
    _cautionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedConcerns.isEmpty) {
      _showSnack('피부 고민을 1개 이상 선택해주세요.');
      return;
    }
    setState(() => _isLoading = true);
    final provider = context.read<AdminProvider>();
    final isEdit = widget.ingredientId != null;

    final success = isEdit
        ? await provider.updateIngredient(
      id: widget.ingredientId!,
      name: _nameController.text.trim(),
      type: _selectedType,
      effectSummary: _effectSummaryController.text.trim(),
      description: _descriptionController.text.trim(),
      effects: _effects,
      cautions: _cautions,
      skinConcerns: _selectedConcerns.map((e) => e.name).toList(),
    )
        : await provider.createIngredient(
      name: _nameController.text.trim(),
      type: _selectedType,
      effectSummary: _effectSummaryController.text.trim(),
      description: _descriptionController.text.trim(),
      effects: _effects,
      cautions: _cautions,
      skinConcerns: _selectedConcerns.map((e) => e.name).toList(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      _showSnack(isEdit ? '수정되었습니다.' : '생성되었습니다.',
          color: AppColors.success);
    } else {
      _showSnack('저장에 실패했습니다.', color: AppColors.error);
    }
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.ingredientId == null ? '성분 추가' : '성분 수정',
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textTitle),
        ),
        centerTitle: true,
      ),
      body: _isInitLoading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label('성분명 *'),
            TextFormField(
              controller: _nameController,
              decoration: _deco('예) 나이아신아마이드'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? '성분명을 입력해주세요.'
                  : null,
            ),
            const SizedBox(height: 20),

            _label('성분 타입 *'),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: _deco(''),
              items: _types
                  .map((t) => DropdownMenuItem(
                  value: t['value'], child: Text(t['label']!)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedType = v ?? 'GENERAL'),
            ),
            const SizedBox(height: 20),

            _label('효과 요약'),
            TextFormField(
              controller: _effectSummaryController,
              decoration: _deco('예) 주름 개선 · 미백 · 피부 재생'),
              maxLength: 100,
            ),
            const SizedBox(height: 20),

            _label('성분 설명 *'),
            TextFormField(
              controller: _descriptionController,
              decoration: _deco('성분에 대한 설명을 입력해주세요.'),
              maxLines: 4,
              validator: (v) => v == null || v.trim().isEmpty
                  ? '설명을 입력해주세요.'
                  : null,
            ),
            const SizedBox(height: 20),

            _label('효과 목록'),
            _ListEditor(
              items: _effects,
              controller: _effectController,
              hintText: '효과 입력 후 추가',
              onAdd: () {
                final v = _effectController.text.trim();
                if (v.isNotEmpty) {
                  setState(() {
                    _effects.add(v);
                    _effectController.clear();
                  });
                }
              },
              onRemove: (i) => setState(() => _effects.removeAt(i)),
            ),
            const SizedBox(height: 20),

            _label('주의사항'),
            _ListEditor(
              items: _cautions,
              controller: _cautionController,
              hintText: '주의사항 입력 후 추가',
              onAdd: () {
                final v = _cautionController.text.trim();
                if (v.isNotEmpty) {
                  setState(() {
                    _cautions.add(v);
                    _cautionController.clear();
                  });
                }
              },
              onRemove: (i) => setState(() => _cautions.removeAt(i)),
            ),
            const SizedBox(height: 20),

            _label('피부 고민 (최대 8개) *'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SkinConcern.values.map((concern) {
                final isSelected =
                _selectedConcerns.contains(concern);
                final isMax = _selectedConcerns.length >= 8;
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _selectedConcerns.remove(concern);
                    } else if (!isMax) {
                      _selectedConcerns.add(concern);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (!isSelected && isMax)
                          ? AppColors.surface.withValues(alpha: 0.5)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.inputBorder,
                      ),
                    ),
                    child: Text(
                      concern.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (!isSelected && isMax)
                            ? AppColors.textSub1
                            : AppColors.textBody,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
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
                  widget.ingredientId == null ? '추가하기' : '수정하기',
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textTitle)),
  );

  InputDecoration _deco(String hint) => InputDecoration(
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
  );
}

class _ListEditor extends StatelessWidget {
  final List<String> items;
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _ListEditor({
    required this.items,
    required this.controller,
    required this.hintText,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('추가',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(entry.value,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textBody)),
                ),
                GestureDetector(
                  onTap: () => onRemove(entry.key),
                  child: const Icon(Icons.close,
                      size: 16, color: AppColors.error),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }
}