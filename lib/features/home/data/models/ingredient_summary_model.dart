class IngredientSummaryModel {
  final int id;
  final String name;
  final String typeTitle;
  final String descriptionSummary;
  final List<String> tags;

  IngredientSummaryModel({
    required this.id,
    required this.name,
    required this.typeTitle,
    required this.descriptionSummary,
    required this.tags,
  });

  factory IngredientSummaryModel.fromJson(Map<String, dynamic> json) {
    return IngredientSummaryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      typeTitle: json['typeTitle'] as String,
      descriptionSummary: json['descriptionSummary'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}