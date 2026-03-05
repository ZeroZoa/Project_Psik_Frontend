import '../../../home/data/models/product_model.dart';

class SkinDiaryResponse {
  final int skinDiaryId;
  final DateTime recordDate;
  final int skinScore;
  final String? skinImageUrl;
  final int? sleepTimeMinutes;
  final int? waterIntakeMl;
  final List<String> diet;
  final List<ProductModel> usedCosmetics;

  SkinDiaryResponse({
    required this.skinDiaryId,
    required this.recordDate,
    required this.skinScore,
    this.skinImageUrl,
    this.sleepTimeMinutes,
    this.waterIntakeMl,
    required this.diet,
    required this.usedCosmetics,
  });

  factory SkinDiaryResponse.fromJson(Map<String, dynamic> json) {
    return SkinDiaryResponse(
      skinDiaryId: json['skinDiaryId'] as int,
      // 백엔드에서 넘어온 UTC Instant 값을 로컬 DateTime으로 파싱
      recordDate: DateTime.parse(json['recordDate'] as String).toLocal(),
      skinScore: json['skinScore'] as int,
      skinImageUrl: json['skinImageUrl'] as String?,
      sleepTimeMinutes: json['sleepTimeMinutes'] as int?,
      waterIntakeMl: json['waterIntakeMl'] as int?,
      diet: (json['diet'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      usedCosmetics: (json['usedCosmetics'] as List<dynamic>?)
          ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}