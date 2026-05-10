import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class CommunityRepository {
  final Dio _dio;

  CommunityRepository(this._dio);

  // ===================== 게시글 =====================

  //홈화면용 3개씩 조회 - (HOT, NEW, POPULAR)
  Future<Map<String, List<PostModel>>> getHomePosts() async {
    try {
      final response = await _dio.get('/api/posts');
      return {
        'hot': (response.data['hot'] as List)
            .map((e) => PostModel.fromJson(e)).toList(),
        'newPosts': (response.data['newPosts'] as List)
            .map((e) => PostModel.fromJson(e)).toList(),
        'popular': (response.data['popular'] as List)
            .map((e) => PostModel.fromJson(e)).toList(),
      };
    } catch (e) {
      throw Exception('홈 게시글 조회 실패: $e');
    }
  }

  Future<List<PostModel>> getHotPosts({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/api/posts/hot',
          queryParameters: {'page': page, 'size': size});
      final List<dynamic> content = response.data['content'];
      return content.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('HOT 게시글 조회 실패: $e');
    }
  }

  Future<List<PostModel>> getNewPosts({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/api/posts/new',
          queryParameters: {'page': page, 'size': size});
      final List<dynamic> content = response.data['content'];
      return content.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('NEW 게시글 조회 실패: $e');
    }
  }

  Future<List<PostModel>> getPopularPosts({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/api/posts/popular',
          queryParameters: {'page': page, 'size': size});
      final List<dynamic> content = response.data['content'];
      return content.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('POPULAR 게시글 조회 실패: $e');
    }
  }

  /// 게시글 상세 조회
  Future<PostModel> getPost(int postId) async {
    try {
      final response = await _dio.get('/api/posts/$postId');
      return PostModel.fromJson(response.data);
    } catch (e) {
      throw Exception('게시글 상세 조회 실패: $e');
    }
  }

  /// 게시글 작성 (이미지 포함)
  Future<PostModel> createPost({
    required String title,
    required String content,
    List<XFile>? imageFiles,
  }) async {
    try {
      final formData = await _buildPostFormData(title, content, imageFiles);

      final response = await _dio.post(
        '/api/posts',
        data: formData,
        // [수정] Options 제거 — Dio가 FormData 감지 시 자동으로 multipart 설정
        // Options를 새로 만들면 인터셉터가 붙인 Authorization 헤더가 날아감
      );
      return PostModel.fromJson(response.data);
    } catch (e) {
      throw Exception('게시글 작성 실패: $e');
    }
  }

  /// 게시글 수정 (이미지 교체)
  Future<PostModel> updatePost(int postId, {
    required String title,
    required String content,
    List<XFile>? imageFiles,
  }) async {
    try {
      final formData = await _buildPostFormData(title, content, imageFiles);

      final response = await _dio.put(
        '/api/posts/$postId',
        data: formData,
        // [수정] Options 제거
      );
      return PostModel.fromJson(response.data);
    } catch (e) {
      throw Exception('게시글 수정 실패: $e');
    }
  }

  /// 게시글 삭제
  Future<void> deletePost(int postId) async {
    try {
      await _dio.delete('/api/posts/$postId');
    } catch (e) {
      throw Exception('게시글 삭제 실패: $e');
    }
  }

  /// 게시글 검색
  Future<List<PostModel>> searchPosts(String keyword, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/api/posts/search',
        queryParameters: {'keyword': keyword, 'page': page, 'size': size},
      );
      final List<dynamic> content = response.data['content'];
      return content.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('게시글 검색 실패: $e');
    }
  }

  /// 게시글 좋아요 토글
  Future<bool> togglePostLike(int postId) async {
    try {
      final response = await _dio.post('/api/posts/$postId/like');
      return response.data['liked'] as bool;
    } catch (e) {
      throw Exception('좋아요 처리 실패: $e');
    }
  }

  // ===================== 마이페이지 =====================

  Future<List<PostModel>> getMyPosts({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/api/posts/me',
          queryParameters: {'page': page, 'size': size});
      final List<dynamic> content = response.data['content'];
      return content.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('내 게시글 조회 실패: $e');
    }
  }

  Future<List<PostModel>> getMyLikedPosts({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/api/posts/me/liked',
          queryParameters: {'page': page, 'size': size});
      final List<dynamic> content = response.data['content'];
      return content.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('좋아요한 게시글 조회 실패: $e');
    }
  }

  Future<List<PostModel>> getMyCommentedPosts({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/api/posts/me/commented',
          queryParameters: {'page': page, 'size': size});
      final List<dynamic> content = response.data['content'];
      return content.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('댓글 단 게시글 조회 실패: $e');
    }
  }

  // ===================== 댓글 =====================

  Future<List<CommentModel>> getComments(int postId) async {
    try {
      final response = await _dio.get('/api/posts/$postId/comments');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => CommentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('댓글 목록 조회 실패: $e');
    }
  }

  Future<CommentModel> createComment(int postId, {
    required String content,
    int? parentId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/posts/$postId/comments',
        data: {'content': content, 'parentId': parentId},
      );
      return CommentModel.fromJson(response.data);
    } catch (e) {
      throw Exception('댓글 작성 실패: $e');
    }
  }

  Future<void> deleteComment(int postId, int commentId) async {
    try {
      await _dio.delete('/api/posts/$postId/comments/$commentId');
    } catch (e) {
      throw Exception('댓글 삭제 실패: $e');
    }
  }

  Future<bool> toggleCommentLike(int postId, int commentId) async {
    try {
      final response =
      await _dio.post('/api/posts/$postId/comments/$commentId/like');
      return response.data['liked'] as bool;
    } catch (e) {
      throw Exception('댓글 좋아요 처리 실패: $e');
    }
  }

  Future<List<CommentModel>> getMyComments({int page = 0, int size = 20}) async {
    try {
      final response = await _dio.get('/api/comments/me',
          queryParameters: {'page': page, 'size': size});
      final List<dynamic> content = response.data['content'];
      return content.map((json) => CommentModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('내 댓글 조회 실패: $e');
    }
  }

  // ===================== 내부 헬퍼 =====================

  /// Multipart FormData 생성 (게시글 작성/수정 공통)
  Future<FormData> _buildPostFormData(
      String title,
      String content,
      List<XFile>? imageFiles,
      ) async {
    final formData = FormData();

    final jsonString = jsonEncode({'title': title, 'content': content});
    formData.files.add(MapEntry(
      'request',
      MultipartFile.fromString(
        jsonString,
        contentType: MediaType('application', 'json'),
      ),
    ));

    if (imageFiles != null) {
      for (final xfile in imageFiles) {
        final filename = xfile.name;

        String mimeType = 'image/jpeg';
        if (filename.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (filename.endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (filename.endsWith('.webp')) {
          mimeType = 'image/webp';
        }

        // Web: fromBytes / Mobile: fromFile
        final multipartFile = kIsWeb
            ? MultipartFile.fromBytes(
          await xfile.readAsBytes(),
          filename: filename,
          contentType: MediaType.parse(mimeType),
        )
            : await MultipartFile.fromFile(
          xfile.path,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        );

        formData.files.add(MapEntry('images', multipartFile));
      }
    }

    return formData;
  }
}