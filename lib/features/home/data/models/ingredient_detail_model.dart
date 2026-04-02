import 'product_model.dart';

class IngredientDetailModel {
  final int id;
  final String name;
  final String typeTitle;
  final String typeDescription;
  final String effectSummary;
  final String description;
  final List<String> effects;
  final List<String> cautions;
  final List<String> skinConcerns;
  final List<ProductModel> products;

  IngredientDetailModel({
    required this.id,
    required this.name,
    required this.typeTitle,
    required this.typeDescription,
    required this.effectSummary,
    required this.description,
    required this.effects,
    required this.cautions,
    required this.skinConcerns,
    required this.products,
  });

  factory IngredientDetailModel.fromJson(Map<String, dynamic> json) {
    return IngredientDetailModel(
      id: json['id'] as int,
      name: json['name'] as String,
      typeTitle: json['typeTitle'] as String,
      typeDescription: json['typeDescription'] as String? ?? '',
      effectSummary: json['effectSummary'] as String? ?? '',
      description: json['description'] as String? ?? '',
      effects: (json['effects'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      cautions: (json['cautions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      skinConcerns: (json['skinConcerns'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      products: (json['products'] as List<dynamic>?)
          ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}