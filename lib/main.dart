import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // [필수] 저장소
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';

// [Common]
import 'common/theme/app_colors.dart';
import 'core/network/auth_interceptor.dart'; // [필수] 인터셉터

// [Feature] - 경로가 view 하위로 변경됨을 반영
import 'features/auth/data/auth_repository.dart';
//import 'features/auth/presentation/view/login_screen.dart';



void main() async {
  //엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  //환경변수 로드
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. Using default values.");
  }

  //보안 저장소
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // 암호화 키가 깨졌을 때(앱 재설치 등) 데이터를 초기화하여 크래시 방지
      resetOnError: true,
    ),
  );

  //네트워크 Dio 설정
  final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  //인터셉터에 (storage, dio) 두 개를 전달
  dio.interceptors.add(AuthInterceptor(storage, dio));

  //앱 실행
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepository(dio, storage),
        ),
      ],
      child: const SkinnerApp(),
    ),
  );
}

class SkinnerApp extends StatelessWidget {
  const SkinnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Psik',
      debugShowCheckedModeBanner: false,

      //테마 설정
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretender',

        // 배경색
        scaffoldBackgroundColor: AppColors.background,

        // 색상 체계 (ColorScheme)
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary, // 형광 라임
          primary: AppColors.primary,
          secondary: AppColors.secondary, // 진한 남색
          surface: AppColors.surface,
          error: AppColors.error,
          brightness: Brightness.light,
        ),

        // 앱바 테마
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textTitle, // 진한 남색
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          iconTheme: IconThemeData(color: AppColors.textTitle),
        ),

        // 버튼 테마 (형광 라임 배경 + 남색 글씨)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.secondary, // 가독성: 남색
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // 라운딩 통일 (16px)
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        // 입력창 테마 (CustomTextField와 스타일 일치)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(color: AppColors.textSub1, fontSize: 14),

          border: _outlineBorder(AppColors.inputBorder),
          enabledBorder: _outlineBorder(AppColors.inputBorder),
          // 포커스 시 형광 라임색 테두리
          focusedBorder: _outlineBorder(AppColors.primary, width: 2),
          errorBorder: _outlineBorder(AppColors.error),
          focusedErrorBorder: _outlineBorder(AppColors.error, width: 2),
        ),

        // 커서 색상
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionHandleColor: AppColors.primary,
        ),
      ),

      // 한국어 지원
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],

      //라우팅
      routerConfig: AppRouter.router,
    );
  }

  // 테두리 스타일 헬퍼 (중복 제거)
  OutlineInputBorder _outlineBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}