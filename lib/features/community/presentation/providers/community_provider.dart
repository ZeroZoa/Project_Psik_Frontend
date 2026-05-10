import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/community_repository.dart';
import 'package:image_picker/image_picker.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityRepository _repository;

  CommunityProvider(this._repository);

  bool isLoading = false;
  bool isDetailLoading = false;
  bool isCommentsLoading = false;

  PostModel? currentPost;
  List<CommentModel> comments = [];
  List<PostModel> hotPosts = [];
  List<PostModel> newPosts = [];
  List<PostModel> popularPosts = [];
  List<PostModel> allPosts = [];
  bool isHomeLoading = false;
  bool isAllPostsLoading = false;
  bool hasMoreAllPosts = true;
  int _allPostsPage = 0;
  String _currentListType = ''; // 'hot' | 'new' | 'popular'

  // ===================== 게시글 목록 =====================

  Future<void> fetchHomePosts() async {
    isHomeLoading = true;
    notifyListeners();
    try {
      final data = await _repository.getHomePosts();
      hotPosts = data['hot'] ?? [];
      newPosts = data['newPosts'] ?? [];
      popularPosts = data['popular'] ?? [];
    } catch (e) {
      debugPrint('홈 게시글 조회 실패: $e');
    } finally {
      isHomeLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPosts(String type, {bool refresh = false}) async {
    if (refresh) {
      _allPostsPage = 0;
      hasMoreAllPosts = true;
      allPosts = [];
      _currentListType = type;
    }
    if (!hasMoreAllPosts || isAllPostsLoading) return;

    isAllPostsLoading = true;
    notifyListeners();

    try {
      List<PostModel> fetchedPosts;
      switch (type) {
        case 'hot':
          fetchedPosts = await _repository.getHotPosts(page: _allPostsPage);
          break;
        case 'popular':
          fetchedPosts = await _repository.getPopularPosts(page: _allPostsPage);
          break;
        default: // 'new'
          fetchedPosts = await _repository.getNewPosts(page: _allPostsPage);
      }
      allPosts.addAll(fetchedPosts);
      _allPostsPage++;
      hasMoreAllPosts = fetchedPosts.length >= 20;
    } catch (e) {
      debugPrint('전체 게시글 조회 실패: $e');
    } finally {
      isAllPostsLoading = false;
      notifyListeners();
    }
  }

  // ===================== 게시글 CRUD =====================

  Future<void> fetchPost(int postId) async {
    isDetailLoading = true;
    notifyListeners();

    try {
      currentPost = await _repository.getPost(postId);
    } catch (e) {
      debugPrint("Error fetching post: $e");
      currentPost = null;
    } finally {
      isDetailLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPost({
    required String title,
    required String content,
    List<XFile>? imageFiles,
  }) async {
    await _repository.createPost(
      title: title,
      content: content,
      imageFiles: imageFiles,
    );
    notifyListeners();
  }

  Future<void> updatePost(int postId, {
    required String title,
    required String content,
    List<XFile>? imageFiles,
  }) async {
    currentPost = await _repository.updatePost(
      postId,
      title: title,
      content: content,
      imageFiles: imageFiles,
    );
    notifyListeners();
  }

  Future<void> deletePost(int postId) async {
    await _repository.deletePost(postId);
    currentPost = null;
    notifyListeners();
  }

  // ===================== 좋아요 =====================

  Future<void> togglePostLike(int postId) async {
    try {
      final liked = await _repository.togglePostLike(postId);

      if (currentPost != null && currentPost!.postId == postId) {
        currentPost = currentPost!.copyWith(
          likeCount: currentPost!.likeCount + (liked ? 1 : -1),
          likedByMe: liked,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error toggling post like: $e");
    }
  }

  // ===================== 댓글 =====================

  Future<void> fetchComments(int postId) async {
    isCommentsLoading = true;
    notifyListeners();

    try {
      comments = await _repository.getComments(postId);
    } catch (e) {
      debugPrint("Error fetching comments: $e");
      comments = [];
    } finally {
      isCommentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> createComment(int postId, {
    required String content,
    int? parentId,
  }) async {
    await _repository.createComment(postId,
        content: content, parentId: parentId);
    await fetchComments(postId);

    if (currentPost != null) {
      currentPost = currentPost!.copyWith(
        commentCount: currentPost!.commentCount + 1,
      );
      notifyListeners();
    }
  }

  Future<void> deleteComment(int postId, int commentId) async {
    await _repository.deleteComment(postId, commentId);
    await fetchComments(postId);
  }

  Future<void> toggleCommentLike(int postId, int commentId) async {
    try {
      await _repository.toggleCommentLike(postId, commentId);
      await fetchComments(postId);
    } catch (e) {
      debugPrint("Error toggling comment like: $e");
    }
  }
}