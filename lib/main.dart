import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// [Router]
import 'core/router/app_router.dart';

// [Common]
import 'common/theme/app_colors.dart';
import 'core/network/auth_interceptor.dart';

// [Feature]
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/home/data/repositories/cosmetics_repository.dart';
import 'features/diary/data/repositories/skin_diary_repository.dart';
import 'features/diary/presentation/providers/skin_diary_provider.dart';
import 'features/community/data/repositories/community_repository.dart';
import 'features/community/presentation/providers/community_provider.dart';

void main() async {
  // 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  // 환경변수 로드
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. Using default values.");
  }

  // 보안 저장소 설정
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
  );

  // 네트워크(Dio) 설정
  final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    headers: {
      'Accept': 'application/json',
    },
    // 웹에서 cross-origin 요청 시 쿠키(HttpOnly 포함)를 전송하도록 설정
    // 이게 없으면 브라우저가 localhost:8080의 쿠키를 localhost:3000 요청에 안 붙임
    extra: {'withCredentials': true},
  ));

  // [수정된 부분] 인터셉터 초기화 및 등록
  // 1. 인스턴스 생성
  final authInterceptor = AuthInterceptor(storage, dio);

  // 2. [중요] 저장소의 토큰을 메모리(변수)로 로드 (비동기)
  // 이걸 해줘야 API 호출 때마다 디스크를 읽지 않아서 속도가 빠릅니다.
  await authInterceptor.init();

  // 3. Dio에 등록
  dio.interceptors.add(authInterceptor);


  // 인스턴스 미리 생성
  // (AuthInterceptor가 적용된 dio를 사용하므로, 토큰이 자동 주입됨)
  final cosmeticsRepository = CosmeticsRepository(dio);
  final skinDiaryRepository = SkinDiaryRepository(dio);
  // [수정] main에서 생성한 storage를 AuthProvider에도 주입하여 인스턴스 통일
  final authProvider = AuthProvider(storage: storage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),

        Provider<AuthRepository>(
          create: (_) => AuthRepository(dio, storage),
        ),

        Provider<CosmeticsRepository>.value(value: cosmeticsRepository),

        //다이어리 Repository + Provider 등록
        Provider<SkinDiaryRepository>.value(value: skinDiaryRepository),

        Provider<CommunityRepository>(
          create: (_) => CommunityRepository(dio),
        ),

        ChangeNotifierProvider<CommunityProvider>(
          create: (_) => CommunityProvider(CommunityRepository(dio)),
        ),

        ChangeNotifierProvider<SkinDiaryProvider>(
          create: (_) => SkinDiaryProvider(skinDiaryRepository),
        ),
      ],
      child: SkinnerApp(authProvider: authProvider),
    ),
  );
}

// ... 아래 SkinnerApp 클래스 등은 기존과 동일합니다 ...
class SkinnerApp extends StatefulWidget {
  final AuthProvider authProvider;

  const SkinnerApp({super.key, required this.authProvider});

  @override
  State<SkinnerApp> createState() => _SkinnerAppState();
}

class _SkinnerAppState extends State<SkinnerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 로그인 상태 체크
    widget.authProvider.checkLoginStatus();

    // 라우터 설정
    _router = AppRouter.router(widget.authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Psik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretender',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textTitle,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          iconTheme: IconThemeData(color: AppColors.textTitle),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.secondary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(color: AppColors.textSub1, fontSize: 14),
          border: _outlineBorder(AppColors.inputBorder),
          enabledBorder: _outlineBorder(AppColors.inputBorder),
          focusedBorder: _outlineBorder(AppColors.primary, width: 2),
          errorBorder: _outlineBorder(AppColors.error),
          focusedErrorBorder: _outlineBorder(AppColors.error, width: 2),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primary,
          selectionHandleColor: AppColors.primary,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      routerConfig: _router,
    );
  }

  OutlineInputBorder _outlineBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}