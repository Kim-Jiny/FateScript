import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/birth_info_provider.dart';
import 'input_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final birthProvider = context.watch<BirthInfoProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'AI 사주 다이어리',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A4FFF),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _authButton(context, authProvider),
                ],
              ),
              const SizedBox(height: 28),
              Text('운명일기', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                '당신의 생년월일과 시간으로\n오늘의 운세와 감정 기록을 연결합니다.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF111827), Color(0xFF312E81)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '오늘의 흐름',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Flexible(
                        child: Text(
                          '사주를 입력하면\n운명선생이 오늘의\n흐름을 알려드립니다.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 4,
                        ),
                      ),
                      const Spacer(),
                      if (birthProvider.hasBirthInfo)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${birthProvider.birthInfo!.birthDate.replaceAll('-', '.')}${birthProvider.birthInfo!.hasTime ? ' ${birthProvider.birthInfo!.birthTime}' : ''}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      else
                        const Text(
                          '아래 버튼으로 사주 정보를 입력해 주세요.',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.6),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _goToInput(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF8A4FFF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    birthProvider.hasBirthInfo ? '사주 정보 수정' : '사주 입력 시작',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authButton(BuildContext context, AuthProvider authProvider) {
    if (authProvider.isLoggedIn) {
      return GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings, size: 16, color: Color(0xFF8A4FFF)),
              SizedBox(width: 6),
              Text(
                '설정',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A4FFF),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login, size: 14, color: Color(0xFF8A4FFF)),
            SizedBox(width: 6),
            Text(
              '로그인',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A4FFF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToInput(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InputScreen()),
    );
  }
}
