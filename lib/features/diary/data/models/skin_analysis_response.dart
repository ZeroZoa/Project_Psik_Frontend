// 피부 분석 결과 응답 모델
class SkinAnalysisResponse {
  final int skinAnalysisId;
  final int skinDiaryId;
  final String imageUrl;
  final int? acneScore;
  final int? wrinkleScore;
  final int? toneScore;
  final int? oilScore;
  final String? summary;
  final String analysisStatus; // PENDING, COMPLETED, FAILED

  SkinAnalysisResponse({
    required this.skinAnalysisId,
    required this.skinDiaryId,
    required this.imageUrl,
    this.acneScore,
    this.wrinkleScore,
    this.toneScore,
    this.oilScore,
    this.summary,
    required this.analysisStatus,
  });

  bool get isCompleted => analysisStatus == 'COMPLETED';
  bool get isFailed => analysisStatus == 'FAILED';
  bool get isPending => analysisStatus == 'PENDING';

  factory SkinAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return SkinAnalysisResponse(
      skinAnalysisId: json['skinAnalysisId'] as int,
      skinDiaryId: json['skinDiaryId'] as int,
      imageUrl: json['imageUrl'] as String,
      acneScore: json['acneScore'] as int?,
      wrinkleScore: json['wrinkleScore'] as int?,
      toneScore: json['toneScore'] as int?,
      oilScore: json['oilScore'] as int?,
      summary: json['summary'] as String?,
      analysisStatus: json['analysisStatus'] as String,
    );
  }
}
