class InquiryModel {
  final int id;
  final String title;
  final String content;
  final bool answered;           // 답변 여부
  final String? answerContent;   // 답변 내용 (없으면 null)
  final DateTime? answeredAt;    // 답변 작성일 (없으면 null)
  final String authorNickname;
  final DateTime createdAt;

  const InquiryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.answered,
    this.answerContent,
    this.answeredAt,
    required this.authorNickname,
    required this.createdAt,
  });

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    return InquiryModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      answered: json['answered'] ?? false,
      answerContent: json['answerContent'],
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt']).toLocal()
          : null,
      authorNickname: json['authorNickname'],
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
    );
  }
}