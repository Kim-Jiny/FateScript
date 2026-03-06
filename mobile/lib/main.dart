import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/birth_info_provider.dart';
import 'providers/fortune_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final birthInfoProvider = BirthInfoProvider();
  await birthInfoProvider.load();

  final fortuneProvider = FortuneProvider();
  await fortuneProvider.loadSavedFortune();
  await fortuneProvider.loadDiaryHistory();

  birthInfoProvider.onBirthInfoChanged = () {
    fortuneProvider.clearAllSaved();
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: birthInfoProvider),
        ChangeNotifierProvider.value(value: fortuneProvider),
      ],
      child: const UnmyeongDiaryApp(),
    ),
  );
}
