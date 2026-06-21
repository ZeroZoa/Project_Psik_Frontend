import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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

// [Feature - Repositories]
import 'features/admin/data/repositories/admin_repository.dart';
import 'features/chat/data/repositories/chat_repository.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/home/data/repositories/cosmetics_repository.dart';
import 'features/home/data/repositories/member_product_repository.dart';
import 'features/diary/data/repositories/skin_diary_repository.dart';
import 'features/diary/data/repositories/skin_analysis_repository.dart';
import 'features/diary/presentation/providers/skin_analysis_provider.dart';
import 'features/community/data/repositories/community_repository.dart';
import 'features/mypage/data/repositories/inquiry_repository.dart';
import 'features/mypage/data/repositories/member_repository.dart';

// [Feature - Providers]
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/diary/presentation/providers/skin_diary_provider.dart';
import 'features/community/presentation/providers/community_provider.dart';
import 'features/mypage/presentation/providers/inquiry_provider.dart';
import 'features/mypage/presentation/providers/mypage_provider.dart';
import 'features/search/data/repositories/search_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // 보안 저장소
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  // Dio 설정
  const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080');

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Accept': 'application/json'},
    extra: {'withCredentials': true},
  ));

  // AuthProvider 초기화
  final authProvider = AuthProvider(storage: storage);
  authProvider.setDio(dio);

  // AuthInterceptor 초기화 및 등록
  final authInterceptor = AuthInterceptor(storage, dio, authProvider);
  await authInterceptor.init();
  dio.interceptors.add(authInterceptor);

  // 로그인 상태 확인
  await authProvider.checkLoginStatus();

  // Repository 인스턴스 생성
  final cosmeticsRepository = CosmeticsRepository(dio);
  final memberProductRepository = MemberProductRepository(dio);
  final skinDiaryRepository = SkinDiaryRepository(dio);
  final skinAnalysisRepository = SkinAnalysisRepository(dio);
  final communityRepository = CommunityRepository(dio);
  final memberRepository = MemberRepository(dio);
  final searchRepository = SearchRepository(dio);
  final inquiryRepository = InquiryRepository(dio);
  final chatRepository = ChatRepository(dio);


  runApp(
    MultiProvider(
      providers: [
        // ── Dio (직접 사용이 필요한 화면을 위해 등록) ──
        Provider<Dio>.value(value: dio),

        // ── Auth ──
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),

        // ── Admin ──
        Provider<AdminRepository>(
          create: (_) => AdminRepository(dio),
        ),

        // ── Home / Contents ──
        Provider<CosmeticsRepository>.value(value: cosmeticsRepository),
        Provider<MemberProductRepository>.value(value: memberProductRepository),

        // ── Diary ──
        Provider<SkinDiaryRepository>.value(value: skinDiaryRepository),
        ChangeNotifierProvider<SkinDiaryProvider>(
          create: (_) => SkinDiaryProvider(skinDiaryRepository),
        ),
        Provider<SkinAnalysisRepository>.value(value: skinAnalysisRepository),
        ChangeNotifierProvider<SkinAnalysisProvider>(
          create: (_) => SkinAnalysisProvider(skinAnalysisRepository),
        ),

        // ── Community ──
        Provider<CommunityRepository>.value(value: communityRepository),
        ChangeNotifierProvider<CommunityProvider>(
          create: (_) => CommunityProvider(communityRepository),
        ),

        // ── Member / Mypage ──
        Provider<MemberRepository>.value(value: memberRepository),

        // ── Search  ──
        Provider<SearchRepository>.value(value: searchRepository),

        // ── Inquiry  ──
        Provider<InquiryRepository>.value(value: inquiryRepository),
        ChangeNotifierProvider<InquiryProvider>(
          create: (_) => InquiryProvider(inquiryRepository),
        ),

        // ── Chat ──
        Provider<ChatRepository>.value(value: chatRepository),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(chatRepository),
        ),


        ChangeNotifierProvider<MypageProvider>(
          create: (_) => MypageProvider(
            memberRepository,
            communityRepository,
            memberProductRepository,
            skinDiaryRepository,
          ),
        ),
      ],
      child: PsikApp(authProvider: authProvider),
    ),
  );
}

class PsikApp extends StatefulWidget {
  final AuthProvider authProvider;

  const PsikApp({super.key, required this.authProvider});

  @override
  State<PsikApp> createState() => _PsikAppState();
}

class _PsikAppState extends State<PsikApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.router(widget.authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Psik | 당신을 위한 피부 공식',
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
      builder: (context, child) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            decoration: BoxDecoration(
              boxShadow: MediaQuery.of(context).size.width > 430
                  ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ]
                  : [],
            ),
            child: ClipRect(child: child),
          ),
        );
      },
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