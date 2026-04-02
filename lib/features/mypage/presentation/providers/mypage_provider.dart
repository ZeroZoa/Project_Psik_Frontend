import 'package:flutter/material.dart';
import '../../../diary/data/models/skin_diary_response.dart';
import '../../../diary/data/repositories/skin_diary_repository.dart';
import '../../data/models/member_model.dart';
import '../../data/repositories/member_repository.dart';
import '../../../community/data/models/post_model.dart';
import '../../../community/data/models/comment_model.dart';
import '../../../community/data/repositories/community_repository.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/data/repositories/member_product_repository.dart';

class MypageProvider extends ChangeNotifier {
  final MemberRepository _memberRepository;
  final CommunityRepository _communityRepository;
  final MemberProductRepository _memberProductRepository;
  final SkinDiaryRepository _skinDiaryRepository;

  MypageProvider(
      this._memberRepository,
      this._communityRepository,
      this._memberProductRepository,
      this._skinDiaryRepository, // ← 추가
      );

  bool isLoading = false;
  MemberModel? member;

  List<PostModel> myPosts = [];
  List<PostModel> likedPosts = [];
  List<PostModel> commentedPosts = [];
  List<CommentModel> myComments = [];
  List<ProductModel> ownedProducts = [];
  List<SkinDiaryResponse> recentDiaries = [];

  Future<void> fetchRecentDiaries() async {
    isTabLoading = true;
    notifyListeners();
    try {
      recentDiaries = await _skinDiaryRepository.getRecentDiaries();
    } catch (e) {
      debugPrint("Error fetching recent diaries: $e");
    } finally {
      isTabLoading = false;
      notifyListeners();
    }
  }

  bool isTabLoading = false;

  Future<void> fetchMyInfo() async {
    isLoading = true;
    notifyListeners();
    try {
      member = await _memberRepository.getMyInfo();
    } catch (e) {
      debugPrint("Error fetching my info: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateNickname(String nickname) async {
    try {
      member = await _memberRepository.updateNickname(nickname);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error updating nickname: $e");
      return false;
    }
  }

  Future<bool> checkNicknameDuplicate(String nickname) async {
    try {
      return await _memberRepository.checkNicknameDuplicate(nickname);
    } catch (e) {
      return true;
    }
  }

  Future<void> fetchMyPosts() async {
    isTabLoading = true;
    notifyListeners();
    try {
      myPosts = await _communityRepository.getMyPosts();
    } catch (e) {
      debugPrint("Error fetching my posts: $e");
    } finally {
      isTabLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLikedPosts() async {
    isTabLoading = true;
    notifyListeners();
    try {
      likedPosts = await _communityRepository.getMyLikedPosts();
    } catch (e) {
      debugPrint("Error fetching liked posts: $e");
    } finally {
      isTabLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCommentedPosts() async {
    isTabLoading = true;
    notifyListeners();
    try {
      commentedPosts = await _communityRepository.getMyCommentedPosts();
    } catch (e) {
      debugPrint("Error fetching commented posts: $e");
    } finally {
      isTabLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyComments() async {
    isTabLoading = true;
    notifyListeners();
    try {
      myComments = await _communityRepository.getMyComments();
    } catch (e) {
      debugPrint("Error fetching my comments: $e");
    } finally {
      isTabLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOwnedProducts() async {
    isTabLoading = true;
    notifyListeners();
    try {
      ownedProducts = await _memberProductRepository.getMyOwnedProducts();
    } catch (e) {
      debugPrint("Error fetching owned products: $e");
    } finally {
      isTabLoading = false;
      notifyListeners();
    }
  }
}