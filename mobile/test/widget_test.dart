import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:unmyeongilgi/app.dart';
import 'package:unmyeongilgi/providers/birth_info_provider.dart';
import 'package:unmyeongilgi/providers/fortune_provider.dart';

void main() {
  testWidgets('renders unmyeong diary home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BirthInfoProvider()),
          ChangeNotifierProvider(create: (_) => FortuneProvider()),
        ],
        child: const UnmyeongDiaryApp(),
      ),
    );

    expect(find.text('운명일기'), findsOneWidget);
    expect(find.text('사주 입력 시작'), findsOneWidget);
    expect(find.text('오늘의 흐름'), findsOneWidget);
  });
}
