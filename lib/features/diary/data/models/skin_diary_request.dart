class SkinDiaryRequest {
  final DateTime recordDate;
  final int skinScore;
  final String? skinImageUrl;
  final int? sleepTimeMinutes;
  final int? waterIntakeMl;
  final List<String>? diet;
  final List<int>? usedProductIds;

  SkinDiaryRequest({
    required this.recordDate,
    required this.skinScore,
    this.skinImageUrl,
    this.sleepTimeMinutes,
    this.waterIntakeMl,
    this.diet,
    this.usedProductIds,
  });

  Map<String, dynamic> toJson() {
    return {
      // Instant 처리를 위해 UTC 변환 후 ISO8601 포맷으로 전송
      'recordDate': recordDate.toUtc().toIso8601String(),
      'skinScore': skinScore,
      'skinImageUrl': skinImageUrl,
      'sleepTimeMinutes': sleepTimeMinutes,
      'waterIntakeMl': waterIntakeMl,
      'diet': diet ?? [],
      'usedProductIds': usedProductIds ?? [],
    };
  }
}