import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../data/models/skin_analysis_response.dart';
import '../../data/repositories/skin_analysis_repository.dart';

// 피부 분석 상태 관리 Provider
class SkinAnalysisProvider extends ChangeNotifier {
  final SkinAnalysisRepository _repository;

  SkinAnalysisProvider(this._repository);

  static const _pollInterval = Duration(seconds: 2);
  static const _maxPollCount = 30; // 최대 1분(2초 * 30회)까지만 폴링

  SkinAnalysisResponse? _analysis;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollTimer;
  bool _disposed = false;

  // 현재 이 Provider가 추적 중인 diaryId.
  // 타이머 콜백/비동기 응답이 도착했을 때 이 값과 다르면 (그 사이 다른 날짜로 이동한 것이므로) 결과를 버린다.
  int? _activeDiaryId;

  SkinAnalysisResponse? get analysis => _analysis;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 피부 분석 요청
  Future<void> analyze(int diaryId, XFile imageFile) async {
    _beginTracking(diaryId);
    _analysis = null;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final result = await _repository.analyze(diaryId, imageFile);
      if (_activeDiaryId != diaryId) return; // 응답 도착 전에 다른 날짜로 이동함

      _analysis = result;
      if (result.isPending) {
        _startPolling(diaryId);
      }
    } catch (e) {
      if (_activeDiaryId != diaryId) return;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (_activeDiaryId == diaryId) {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  /// 기존 분석 결과 조회
  Future<void> fetchAnalysis(int diaryId) async {
    _beginTracking(diaryId);
    _analysis = null;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final result = await _repository.getAnalysis(diaryId);
      if (_activeDiaryId != diaryId) return; // 응답 도착 전에 다른 날짜로 이동함

      _analysis = result;
      // 화면 진입 시점에 아직 분석 중이던 건일 수 있으므로, 이어서 폴링 시작
      if (result != null && result.isPending) {
        _startPolling(diaryId);
      }
    } catch (e) {
      if (_activeDiaryId != diaryId) return;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (_activeDiaryId == diaryId) {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  /// PENDING 상태일 때 완료/실패로 바뀔 때까지 주기적으로 결과를 다시 조회
  void _startPolling(int diaryId) {
    _pollTimer?.cancel();
    int attempts = 0;

    _pollTimer = Timer.periodic(_pollInterval, (timer) async {
      // 폴링 도중 다른 날짜로 이동했으면 즉시 중단 — 다른 날짜 화면에 이 결과가 덮어써지는 것을 방지
      if (_activeDiaryId != diaryId) {
        timer.cancel();
        return;
      }

      attempts++;

      if (attempts > _maxPollCount) {
        timer.cancel();
        _errorMessage = '분석이 지연되고 있습니다. 잠시 후 다시 확인해주세요.';
        _safeNotify();
        return;
      }

      try {
        final result = await _repository.getAnalysis(diaryId);
        if (_activeDiaryId != diaryId) {
          timer.cancel();
          return;
        }
        if (result == null) return;

        _analysis = result;
        _safeNotify();

        if (!result.isPending) {
          timer.cancel();
        }
      } catch (e) {
        // 폴링 중 일시적 네트워크 오류는 무시하고 다음 주기에 재시도
      }
    });
  }

  /// 분석 상태 초기화
  void reset() {
    _beginTracking(null);
    _analysis = null;
    _errorMessage = null;
    _isLoading = false;
    _safeNotify();
  }

  /// 새 diaryId로 추적 대상을 전환 — 기존 타이머는 즉시 취소하고,
  /// 이미 진행 중이던 요청의 응답은 (activeDiaryId 불일치로) 도착해도 무시된다.
  void _beginTracking(int? diaryId) {
    _pollTimer?.cancel();
    _pollTimer = null;
    _activeDiaryId = diaryId;
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _pollTimer?.cancel();
    super.dispose();
  }
}
