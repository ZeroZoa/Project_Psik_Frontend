import 'package:flutter/material.dart';
import '../../data/models/InquiryModel.dart';
import '../../data/repositories/inquiry_repository.dart';

/// 문의하기 상태 관리 — CommunityProvider 패턴 동일
class InquiryProvider extends ChangeNotifier {
  final InquiryRepository _repository;
  InquiryProvider(this._repository);

  List<InquiryModel> myInquiries = [];
  bool isLoading = false;
  bool isSubmitting = false;

  /// 내 문의 목록 조회
  Future<void> fetchMyInquiries() async {
    isLoading = true;
    notifyListeners();
    try {
      myInquiries = await _repository.getMyInquiries();
    } catch (e) {
      debugPrint('문의 목록 조회 실패: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 문의 등록 — 성공 시 목록 맨 앞에 추가 후 true 반환
  Future<bool> submitInquiry({
    required String title,
    required String content,
  }) async {
    isSubmitting = true;
    notifyListeners();
    try {
      final inquiry = await _repository.createInquiry(
        title: title,
        content: content,
      );
      myInquiries.insert(0, inquiry);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('문의 등록 실패: $e');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}