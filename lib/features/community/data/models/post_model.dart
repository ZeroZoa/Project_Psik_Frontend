class PostModel {
  final int postId;
  final String authorUuid;
  final String authorNickname;
  final String? authorProfileImageUrl;
  final String title;
  final String? content;
  final List<String> imageUrls; // [추가] 이미지 URL 목록
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool likedByMe;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.postId,
    required this.authorUuid,
    required this.authorNickname,
    this.authorProfileImageUrl,
    required this.title,
    this.content,
    required this.imageUrls,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.likedByMe,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      postId: json['postId'] as int,
      authorUuid: json['authorUuid'] as String,
      authorNickname: json['authorNickname'] as String,
      authorProfileImageUrl: json['authorProfileImageUrl'] as String?,
      title: json['title'] as String,
      content: json['content'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }

  // 좋아요 토글 등에서 copyWith로 사용
  PostModel copyWith({
    int? likeCount,
    bool? likedByMe,
    int? commentCount,
    int? viewCount,
  }) {
    return PostModel(
      postId: postId,
      authorUuid: authorUuid,
      authorNickname: authorNickname,
      authorProfileImageUrl: authorProfileImageUrl,
      title: title,
      content: content,
      imageUrls: imageUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      likedByMe: likedByMe ?? this.likedByMe,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}