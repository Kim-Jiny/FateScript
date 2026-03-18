import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/fortune_provider.dart';
import 'providers/compatibility_prefill_provider.dart';
import 'screens/home_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/name_screen.dart';
import 'screens/fortune_screen.dart';
import 'screens/compatibility_screen.dart';
import 'screens/input_screen.dart';
import 'widgets/bottom_nav.dart';

class UnmyeongDiaryApp extends StatelessWidget {
  const UnmyeongDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF6EFE5);
    const surface = Color(0xFFFFFBF5);
    const primary = Color(0xFF8A4FFF);
    const accent = Color(0xFF1F2937);

    return MaterialApp(
      title: '운명일기',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
          surface: surface,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: accent,
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF4B5563),
          ),
        ),
      ),
      builder: (context, child) {
        final scale = Platform.isAndroid ? 1.0 : 1.15;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        );
      },
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final AppLinks _appLinks;

  static const _screens = [
    HomeScreen(),
    DailyScreen(),
    NameScreen(),
    FortuneScreen(),
    CompatibilityScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // 앱이 링크로 시작된 경우
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleDeepLink(initialUri);

    // 앱이 이미 실행 중일 때 링크 수신
    _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    // /ref/{code} 패턴 파싱
    if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'ref') {
      final code = uri.pathSegments[1];
      if (code.isNotEmpty && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InputScreen(referralCode: code),
          ),
        );
      }
    }

    // /compat?birthDate=...&birthTime=...&gender=... 궁합 딥링크
    if (uri.pathSegments.length == 1 && uri.pathSegments[0] == 'compat') {
      final birthDate = uri.queryParameters['birthDate'];
      final birthTime = uri.queryParameters['birthTime'] ?? 'unknown';
      final gender = uri.queryParameters['gender'] ?? 'male';
      if (birthDate != null && birthDate.isNotEmpty && mounted) {
        context.read<CompatibilityPrefillProvider>().setPrefill(
          birthDate: birthDate,
          birthTime: birthTime,
          gender: gender,
        );
        setState(() => _currentIndex = 4); // 궁합 탭
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          final isLoading = context.read<FortuneProvider>().isLoading;
          if (isLoading) return;
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}
