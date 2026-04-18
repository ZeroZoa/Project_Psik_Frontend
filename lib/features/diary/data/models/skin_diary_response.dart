import '../../../home/data/models/product_model.dart';

class SkinDiaryResponse {
  final int skinDiaryId;
  final DateTime recordDate;
  final int skinScore;
  final int? sleepTimeMinutes;
  final int? waterIntakeMl;
  final List<String> diet;
  final List<ProductModel> usedCosmetics;
  final DateTime createdAt;
  final DateTime updatedAt;

  SkinDiaryResponse({
    required this.skinDiaryId,
    required this.recordDate,
    required this.skinScore,
    this.sleepTimeMinutes,
    this.waterIntakeMl,
    required this.diet,
    required this.usedCosmetics,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SkinDiaryResponse.fromJson(Map<String, dynamic> json) {
    return SkinDiaryResponse(
      skinDiaryId: json['skinDiaryId'] as int,
      recordDate: DateTime.parse(json['recordDate'] as String).toLocal(),
      skinScore: json['skinScore'] as int,
      sleepTimeMinutes: json['sleepTimeMinutes'] as int?,
      waterIntakeMl: json['waterIntakeMl'] as int?,
      diet: (json['diet'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      usedCosmetics: (json['usedCosmetics'] as List<dynamic>?)
          ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(
          (json['createdAt'] as String?) ?? DateTime.now().toUtc().toIso8601String()
      ).toLocal(),
      updatedAt: DateTime.parse(
          (json['updatedAt'] as String?) ?? DateTime.now().toUtc().toIso8601String()
      ).toLocal(),
    );
  }
}