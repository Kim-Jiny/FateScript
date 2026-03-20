import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../providers/ticket_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _storage = StorageService();

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
      if (context.mounted) {
        await _promptReferralCode(context);
        if (context.mounted) Navigator.of(context).pop(true);
      }
    }
  }

  void _signInWithApple(BuildContext context, AuthProvider authProvider) async {
    final success = await authProvider.signInWithApple();
    if (success && context.mounted) {
      await _syncAfterLogin(context);
      if (context.mounted) {
        await _promptReferralCode(context);
        if (context.mounted) Navigator.of(context).pop(true);
      }
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

  Future<void> _promptReferralCode(BuildContext context) async {
    // 이미 추천 코드를 입력한 적이 있으면 건너뛰기
    if (await _storage.hasPromptedReferral()) return;

    // 서버에서 이미 추천인이 적용된 유저인지 확인
    try {
      final hasReferrer = await ApiService().checkHasReferrer();
      if (hasReferrer) {
        await _storage.setReferralPrompted();
        return;
      }
    } catch (_) {}

    // 딥링크로 저장된 코드가 있으면 자동 적용
    final pendingCode = await _storage.loadPendingReferralCode();
    if (pendingCode != null && pendingCode.isNotEmpty) {
      await _storage.clearPendingReferralCode();
      await _storage.setReferralPrompted();
      try {
        final result = await ApiService().applyReferralCode(pendingCode);
        if (context.mounted && result['applied'] == true) {
          final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
          await ticketProvider.loadBalance();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('추천 코드가 적용되었습니다! 보너스 티켓 3장 지급!')),
            );
          }
        }
      } catch (_) {}
      return;
    }

    if (!context.mounted) return;

    // 수동 입력 다이얼로그
    final code = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('추천인 코드'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '추천인 코드가 있으시면 입력해 주세요.\n추천인과 본인 모두 보너스 티켓 3장을 받습니다!',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: '추천인 코드 입력',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: const Icon(Icons.card_giftcard, size: 20, color: Color(0xFF8A4FFF)),
                ),
                style: const TextStyle(fontSize: 14, letterSpacing: 2),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('건너뛰기', style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                Navigator.pop(ctx, text.isNotEmpty ? text : null);
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8A4FFF)),
              child: const Text('적용'),
            ),
          ],
        );
      },
    );

    await _storage.setReferralPrompted();

    if (code != null && code.isNotEmpty && context.mounted) {
      try {
        final result = await ApiService().applyReferralCode(code);
        if (context.mounted) {
          if (result['applied'] == true) {
            final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
            await ticketProvider.loadBalance();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('추천 코드가 적용되었습니다! 보너스 티켓 3장 지급!')),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'] as String? ?? '추천 코드를 적용할 수 없습니다.')),
              );
            }
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('추천 코드 적용에 실패했습니다.')),
          );
        }
      }
    }
  }
}
