import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:provider/provider.dart';

import 'package:unmyeongilgi/providers/auth_provider.dart' as auth_provider;
import 'package:unmyeongilgi/providers/birth_info_provider.dart';
import 'package:unmyeongilgi/providers/fortune_provider.dart';
import 'package:unmyeongilgi/screens/home_screen.dart';

class _FakeAuthProvider extends ChangeNotifier
    implements auth_provider.AuthProvider {
  @override
  User? get user => null;

  @override
  bool get isLoggedIn => false;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  String? get displayName => null;

  @override
  String? get email => null;

  @override
  String? get photoUrl => null;

  @override
  Future<void> waitForAuthReady() async {}

  @override
  Future<String?> getIdToken() async => null;

  @override
  Future<void> updateApiToken() async {}

  @override
  Future<bool> signInWithGoogle() async => false;

  @override
  Future<bool> signInWithApple() async => false;

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> deleteAccount() async => false;

  @override
  void clearError() {}
}

void main() {
  testWidgets('renders home screen shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ListenableProvider<auth_provider.AuthProvider>.value(
            value: _FakeAuthProvider(),
          ),
          ChangeNotifierProvider(create: (_) => BirthInfoProvider()),
          ChangeNotifierProvider(create: (_) => FortuneProvider()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('운명일기'), findsOneWidget);
    expect(find.text('사주 입력 시작'), findsOneWidget);
    expect(find.text('바로가기'), findsOneWidget);
  });
}
