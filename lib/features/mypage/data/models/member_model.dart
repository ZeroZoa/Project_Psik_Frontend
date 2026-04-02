import '../../../auth/domain/enums/gender.dart';
import '../../../auth/domain/enums/skin_concern.dart';
import '../../../auth/domain/enums/skin_type.dart';

class MemberModel {
  final String uuid;
  final String? email;
  final String nickname;
  final String? profileImageUrl;
  final String role;
  final Gender? gender;
  final int? birthYear;
  final SkinType? skinType;
  final List<SkinConcern> skinConcerns;
  final bool profileComplete;

  MemberModel({
    required this.uuid,
    this.email,
    required this.nickname,
    this.profileImageUrl,
    required this.role,
    this.gender,
    this.birthYear,
    this.skinType,
    required this.skinConcerns,
    required this.profileComplete,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      uuid: json['uuid'] as String,
      email: json['email'] as String?,
      nickname: json['nickname'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      role: json['role'] as String? ?? 'USER',
      gender: json['gender'] != null
          ? Gender.values.byName(json['gender'] as String)
          : null,
      birthYear: json['birthYear'] as int?,
      skinType: json['skinType'] != null
          ? SkinType.values.byName(json['skinType'] as String)
          : null,
      skinConcerns: (json['skinConcerns'] as List<dynamic>?)
          ?.map((e) => SkinConcern.values.byName(e as String))
          .toList() ??
          [],
      profileComplete: json['profileComplete'] as bool? ?? false,
    );
  }
}