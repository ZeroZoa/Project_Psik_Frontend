class SkinDiaryRequest {
  final DateTime recordDate;
  final int skinScore;
  final int? sleepTimeMinutes;
  final int? waterIntakeMl;
  final List<String>? diet;
  final List<int>? usedProductIds;

  SkinDiaryRequest({
    required this.recordDate,
    required this.skinScore,
    this.sleepTimeMinutes,
    this.waterIntakeMl,
    this.diet,
    this.usedProductIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'recordDate': recordDate.toUtc().toIso8601String(),
      'skinScore': skinScore,
      'sleepTimeMinutes': sleepTimeMinutes,
      'waterIntakeMl': waterIntakeMl,
      'diet': diet ?? [],
      'usedProductIds': usedProductIds ?? [],
    };
  }
}