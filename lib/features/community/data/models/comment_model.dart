class CommentModel {
  final int commentId;
  final String authorUuid;
  final String authorNickname;
  final String? authorProfileImageUrl;
  final String content;
  final int likeCount;
  final bool likedByMe;
  final int? parentId;
  final List<CommentModel> children;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommentModel({
    required this.commentId,
    required this.authorUuid,
    required this.authorNickname,
    this.authorProfileImageUrl,
    required this.content,
    required this.likeCount,
    required this.likedByMe,
    this.parentId,
    required this.children,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['commentId'] as int,
      authorUuid: json['authorUuid'] as String,
      authorNickname: json['authorNickname'] as String,
      authorProfileImageUrl: json['authorProfileImageUrl'] as String?,
      content: json['content'] as String,
      likeCount: json['likeCount'] as int? ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      parentId: json['parentId'] as int?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }
}