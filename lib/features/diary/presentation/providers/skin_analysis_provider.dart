import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../data/models/skin_analysis_response.dart';
import '../../data/repositories/skin_analysis_repository.dart';

// 피부 분석 상태 관리 Provider
class SkinAnalysisProvider extends ChangeNotifier {
  final SkinAnalysisRepository _repository;

  SkinAnalysisProvider(this._repository);

  SkinAnalysisResponse? _analysis;
  bool _isLoading = false;
  String? _errorMessage;

  SkinAnalysisResponse? get analysis => _analysis;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 피부 분석 요청
  Future<void> analyze(int diaryId, XFile imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _analysis = await _repository.analyze(diaryId, imageFile);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 기존 분석 결과 조회
  Future<void> fetchAnalysis(int diaryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _analysis = await _repository.getAnalysis(diaryId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 분석 상태 초기화
  void reset() {
    _analysis = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
