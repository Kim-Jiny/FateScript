import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/birth_info_provider.dart';
import 'providers/fortune_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authProvider = AuthProvider();
  await authProvider.waitForAuthReady();

  final birthInfoProvider = BirthInfoProvider();
  await birthInfoProvider.load();

  // 로그인 상태면 서버와 사주 동기화
  if (authProvider.isLoggedIn) {
    await birthInfoProvider.syncWithServer();
  }

  final fortuneProvider = FortuneProvider();
  await fortuneProvider.loadSavedFortune();

  birthInfoProvider.onBirthInfoChanged = () {
    fortuneProvider.clearAllSaved();
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: birthInfoProvider),
        ChangeNotifierProvider.value(value: fortuneProvider),
      ],
      child: const UnmyeongDiaryApp(),
    ),
  );
}
