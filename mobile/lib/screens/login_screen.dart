import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../providers/ticket_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Icon(Icons.auto_awesome,
                  size: 64, color: Color(0xFF8A4FFF)),
              const SizedBox(height: 24),
              const Text(
                '운명일기',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '로그인하면 사주 정보가 동기화되고\n궁합 히스토리를 관리할 수 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const Spacer(),
              if (authProvider.error != null) ...[
                Text(
                  authProvider.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: authProvider.isLoading
                      ? null
                      : () => _signInWithGoogle(context, authProvider),
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('Google로 계속하기'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    foregroundColor: const Color(0xFF1F2937),
                  ),
                ),
              ),
              if (Platform.isIOS) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _signInWithApple(context, authProvider),
                    icon: const Icon(Icons.apple, size: 24),
                    label: const Text('Apple로 계속하기'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  '게스트로 계속하기',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _signInWithGoogle(BuildContext context, AuthProvider authProvider) async {
    final success = await authProvider.signInWithGoogle();
    if (success && context.mounted) {
      await _syncAfterLogin(context);
      if (context.mounted) Navigator.of(context).pop(true);
    }
  }

  void _signInWithApple(BuildContext context, AuthProvider authProvider) async {
    final success = await authProvider.signInWithApple();
    if (success && context.mounted) {
      await _syncAfterLogin(context);
      if (context.mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _syncAfterLogin(BuildContext context) async {
    final birthProvider =
        Provider.of<BirthInfoProvider>(context, listen: false);
    await birthProvider.syncWithServer();
    final ticketProvider =
        Provider.of<TicketProvider>(context, listen: false);
    await ticketProvider.loadBalance();
    final fortuneProvider =
        Provider.of<FortuneProvider>(context, listen: false);
    await fortuneProvider.loadFromServer(birthProvider.birthInfo);
  }
}
