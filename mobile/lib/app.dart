import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/diary_screen.dart';
import 'screens/fortune_screen.dart';
import 'screens/compatibility_screen.dart';
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
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: accent,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Color(0xFF4B5563),
          ),
        ),
      ),
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

  static const _screens = [
    HomeScreen(),
    DailyScreen(),
    DiaryScreen(),
    FortuneScreen(),
    CompatibilityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
