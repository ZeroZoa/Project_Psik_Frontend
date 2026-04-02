import 'package:dio/dio.dart';
import '../../../auth/domain/enums/gender.dart';
import '../../../auth/domain/enums/skin_concern.dart';
import '../../../auth/domain/enums/skin_type.dart';
import '../models/member_model.dart';

class MemberRepository {
  final Dio _dio;

  MemberRepository(this._dio);

  /// 내 정보 조회
  Future<MemberModel> getMyInfo() async {
    try {
      final response = await _dio.get('/api/members/me');
      return MemberModel.fromJson(response.data);
    } catch (e) {
      throw Exception('내 정보 조회 실패: $e');
    }
  }

  /// 닉네임 수정
  Future<MemberModel> updateNickname(String nickname) async {
    try {
      final response = await _dio.patch(
        '/api/members/me/nickname',
        data: {'nickname': nickname},
      );
      return MemberModel.fromJson(response.data);
    } catch (e) {
      throw Exception('닉네임 수정 실패: $e');
    }
  }

  /// 피부 고민 수정
  Future<MemberModel> updateSkinConcerns(List<SkinConcern> skinConcerns) async {
    try {
      final response = await _dio.patch(
        '/api/members/me/skin-concerns',
        data: {
          'skinConcerns': skinConcerns.map((e) => e.name).toList(),
        },
      );
      return MemberModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? '피부 고민 수정 실패');
    }
  }

  /// 닉네임 중복 확인
  Future<bool> checkNicknameDuplicate(String nickname) async {
    try {
      final response = await _dio.get(
        '/api/members/check-nickname',
        queryParameters: {'nickname': nickname},
      );
      return response.data as bool; // true = 중복
    } catch (e) {
      throw Exception('닉네임 중복 확인 실패: $e');
    }
  }

  ///프로필 셋팅
  Future<MemberModel> setupProfile({
    required String nickname,
    required Gender gender,
    required int birthYear,
    required SkinType skinType,
    required List<SkinConcern> skinConcerns,
  }) async {
    try {
      final response = await _dio.post(
        '/api/members/me/profile-setup',
        data: {
          'nickname': nickname,
          'gender': gender.name,
          'birthYear': birthYear,
          'skinType': skinType.name,
          'skinConcerns': skinConcerns.map((e) => e.name).toList(),
        },
      );
      return MemberModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? '프로필 설정 실패');
    }
  }
}