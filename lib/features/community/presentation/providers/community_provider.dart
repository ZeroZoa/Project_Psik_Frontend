import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';
import '../../data/models/comment_model.dart';
import '../../data/repositories/community_repository.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityRepository _repository;

  CommunityProvider(this._repository);

  bool isLoading = false;
  bool isDetailLoading = false;
  bool isCommentsLoading = false;

  List<PostModel> posts = [];
  String currentSort = 'latest';
  int _currentPage = 0;
  bool hasMore = true;

  PostModel? currentPost;
  List<CommentModel> comments = [];

  // ===================== 게시글 목록 =====================

  Future<void> changeSortAndRefresh(String sort) async {
    currentSort = sort;
    await refreshPosts();
  }

  Future<void> refreshPosts() async {
    _currentPage = 0;
    hasMore = true;
    isLoading = true;
    notifyListeners();

    try {
      posts = await _repository.getPosts(sort: currentSort, page: 0);
      _currentPage = 1;
      hasMore = posts.length >= 20;
    } catch (e) {
      debugPrint("Error refreshing posts: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePosts() async {
    if (!hasMore || isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      final newPosts = await _repository.getPosts(
          sort: currentSort, page: _currentPage);
      posts.addAll(newPosts);
      _currentPage++;
      hasMore = newPosts.length >= 20;
    } catch (e) {
      debugPrint("Error loading more posts: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchPosts(String keyword) async {
    isLoading = true;
    notifyListeners();

    try {
      posts = await _repository.searchPosts(keyword);
      hasMore = false;
    } catch (e) {
      debugPrint("Error searching posts: $e");
    } finally {
      isLoading = false;
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

  Future<PostModel> createPost({
    required String title,
    required String content,
    List<String>? imagePaths,
  }) async {
    final post = await _repository.createPost(
      title: title,
      content: content,
      imagePaths: imagePaths,
    );
    posts.insert(0, post);
    notifyListeners();
    return post;
  }

  Future<void> updatePost(int postId, {
    required String title,
    required String content,
    List<String>? imagePaths,
  }) async {
    currentPost = await _repository.updatePost(
      postId,
      title: title,
      content: content,
      imagePaths: imagePaths,
    );
    final index = posts.indexWhere((p) => p.postId == postId);
    if (index != -1) posts[index] = currentPost!;
    notifyListeners();
  }

  Future<void> deletePost(int postId) async {
    await _repository.deletePost(postId);
    posts.removeWhere((p) => p.postId == postId);
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

      final index = posts.indexWhere((p) => p.postId == postId);
      if (index != -1) {
        posts[index] = posts[index].copyWith(
          likeCount: posts[index].likeCount + (liked ? 1 : -1),
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