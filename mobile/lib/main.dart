import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/birth_info_provider.dart';
import 'providers/fortune_provider.dart';
import 'providers/ticket_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authProvider = AuthProvider();
  await authProvider.waitForAuthReady();
  debugPrint('[Main] authProvider.isLoggedIn=${authProvider.isLoggedIn}');

  final birthInfoProvider = BirthInfoProvider();
  await birthInfoProvider.load();
  debugPrint('[Main] birthInfo loaded: ${birthInfoProvider.hasBirthInfo}');

  // 로그인 상태면 서버와 사주 동기화
  if (authProvider.isLoggedIn) {
    debugPrint('[Main] Starting syncWithServer...');
    await birthInfoProvider.syncWithServer();
    debugPrint('[Main] syncWithServer done');
  } else {
    debugPrint('[Main] Not logged in, skipping sync');
  }

  final fortuneProvider = FortuneProvider();
  await fortuneProvider.loadSavedFortune();

  final ticketProvider = TicketProvider();
  await ticketProvider.initialize();

  if (authProvider.isLoggedIn) {
    await ticketProvider.loadBalance();
  }

  birthInfoProvider.onBirthInfoChanged = () {
    fortuneProvider.clearAllSaved();
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: birthInfoProvider),
        ChangeNotifierProvider.value(value: fortuneProvider),
        ChangeNotifierProvider.value(value: ticketProvider),
      ],
      child: const UnmyeongDiaryApp(),
    ),
  );
}
