class IngredientSummaryModel {
  final int id;
  final String name;
  final String typeTitle;
  final String effectSummary;
  final String descriptionSummary;
  final List<String> skinConcerns;

  IngredientSummaryModel({
    required this.id,
    required this.name,
    required this.typeTitle,
    required this.effectSummary,
    required this.descriptionSummary,
    required this.skinConcerns,
  });

  factory IngredientSummaryModel.fromJson(Map<String, dynamic> json) {
    return IngredientSummaryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      typeTitle: json['typeTitle'] as String,
      effectSummary: json['effectSummary'] as String? ?? '',
      descriptionSummary: json['descriptionSummary'] as String? ?? '',
      skinConcerns: (json['skinConcerns'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }
}