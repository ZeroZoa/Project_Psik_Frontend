import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  // 메인 청록색
  static const Color primary = Color(0xFF36BC9B);
  // 포인트 레드
  static const Color subPrimary = Color(0xFFFF383C);

  // 청록색의 차가운 느낌을 받아주는 묵직한 네이비
  static const Color secondary = Color(0xFF1E293B);

  //상태 컬러
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);

  //배경 컬러
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFF1F5F4);

  //텍스트 제목: 청록색에 어울리는 진한 검정
  static const Color textTitle = Color(0xFF111827);

  //청록색에 어울리는 진한 회색
  static const Color textBody = Color(0xFF475569);

  //서브 텍스트
  static const Color textSub1 = Color(0xFFD9D9D9);
  static const Color textSub2 = Color(0xFF767676);

  // 테두리: 청록색과 조화되는 쿨톤 그레이
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputBorderActive = primary;
}