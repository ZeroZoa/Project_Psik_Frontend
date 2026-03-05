import 'package:flutter/material.dart';
import '../../data/repositories/skin_diary_repository.dart';
import '../../data/models/skin_diary_request.dart';
import '../../data/models/skin_diary_response.dart';

class SkinDiaryProvider extends ChangeNotifier {
  final SkinDiaryRepository _repository;

  SkinDiaryProvider(this._repository);

  bool isLoading = false;

  // 현재 화면에서 조회된 다이어리 데이터 (없으면 null)
  SkinDiaryResponse? currentDiary;

  //현재 조회한 월에서 기록이 존재하는 날짜(day)들의 Set
  Set<int> recordedDays = {};

  //현재 조회된 월
  int _loadedYear = 0;
  int _loadedMonth = 0;

  //다이어리 생성 (POST)
  Future<void> createDiary(SkinDiaryRequest request) async {
    isLoading = true;
    notifyListeners();

    try {
      currentDiary = await _repository.createDiary(request);
      debugPrint("다이어리 생성 성공: ${currentDiary?.skinDiaryId}");
    } catch (e) {
      debugPrint("Error creating diary: $e");
      rethrow; // UI에서 SnackBar로 에러를 보여주기 위해 에러를 던짐
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  //선택된 날짜의 다이어리 조회 (GET)
  Future<void> fetchDiaryByDate(DateTime date) async {
    isLoading = true;
    notifyListeners();

    try {
      currentDiary = await _repository.getDiaryByDate(date);
    } catch (e) {
      debugPrint("Error fetching diary: $e");
      currentDiary = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  //선택된 월별 다이어리 목록 조회 → 기록 있는 날짜 Set 갱신 (GET)
  Future<void> fetchMonthlyDiaries(int year, int month, {bool force = false}) async {
    // 이미 같은 월을 로드했으면 스킵 (force가 아닌 경우)
    if (!force && _loadedYear == year && _loadedMonth == month) return;

    try {
      final diaries = await _repository.getMonthlyDiaries(year, month);
      recordedDays = diaries.map((d) => d.recordDate.day).toSet();
      _loadedYear = year;
      _loadedMonth = month;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching monthly diaries: $e");
    }
  }

  //다이어리 수정 (PUT)
  Future<void> updateDiary(int diaryId, SkinDiaryRequest request) async {
    isLoading = true;
    notifyListeners();

    try {
      currentDiary = await _repository.updateDiary(diaryId, request);
      debugPrint("다이어리 수정 성공: ${currentDiary?.skinDiaryId}");
    } catch (e) {
      debugPrint("Error updating diary: $e");
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  //다이어리 삭제 (DELETE)
  Future<void> deleteDiary(int diaryId) async {
    isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteDiary(diaryId);
      currentDiary = null; // 삭제 성공 시 화면 초기화
      debugPrint("다이어리 삭제 성공");
    } catch (e) {
      debugPrint("Error deleting diary: $e");
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}