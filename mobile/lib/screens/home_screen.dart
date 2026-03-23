import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../services/api_service.dart';
import 'input_screen.dart';
import 'daily_screen.dart';
import 'fortune_screen.dart';
import 'name_screen.dart';
import 'auspicious_date_screen.dart';
import 'compatibility_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _referralCode;
  bool _referralLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    setState(() => _referralLoading = true);
    try {
      final code = await ApiService().getReferralCode();
      if (mounted) setState(() => _referralCode = code);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _referralLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthProvider = context.watch<BirthInfoProvider>();
    final authProvider = context.watch<AuthProvider>();
    final fortuneProvider = context.watch<FortuneProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  if (!authProvider.isLoggedIn)
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                            Icon(Icons.person, size: 16, color: Color(0xFF8A4FFF)),
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
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Text('운명일기', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                '당신의 생년월일과 시간으로\n오늘의 운세와 감정 기록을 연결합니다.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              // 오늘의 운세 요약 카드
              _dailySummaryCard(context, birthProvider, fortuneProvider),
              const SizedBox(height: 20),

              // 기능 바로가기 2x2 그리드
              const Text(
                '바로가기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: [
                  _shortcutCard(
                    icon: Icons.auto_awesome,
                    title: '사주 분석',
                    color: const Color(0xFF8A4FFF),
                    onTap: () => _push(context, const FortuneScreen()),
                  ),
                  _shortcutCard(
                    icon: Icons.favorite,
                    title: '궁합',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      // 궁합 탭으로 이동 — 부모 MainShell의 탭 변경 불가하므로 push
                      _push(context, const CompatibilityScreen());
                    },
                  ),
                  _shortcutCard(
                    icon: Icons.text_fields,
                    title: '성명학',
                    color: const Color(0xFF3B82F6),
                    onTap: () => _push(context, const NameScreen()),
                  ),
                  _shortcutCard(
                    icon: Icons.calendar_month,
                    title: '택일/길일',
                    color: const Color(0xFFF59E0B),
                    onTap: () => _push(context, const AuspiciousDateScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 사주 입력 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InputScreen()),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF8A4FFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(birthProvider.hasBirthInfo ? '사주 정보 수정' : '사주 입력 시작'),
                ),
              ),
              const SizedBox(height: 20),

              // 추천 코드 공유 CTA
              if (authProvider.isLoggedIn) _referralBanner(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dailySummaryCard(BuildContext context, BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    final daily = fortuneProvider.dailyFortune;

    return Container(
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
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          if (daily != null) ...[
            Text(
              '오늘의 일진: ${daily.iljinHanja} (${daily.iljinHangul})',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '오늘의 운세가 준비되었어요.\n사주 탭에서 자세히 확인하세요.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ] else ...[
            const Text(
              '사주를 입력하면\n운명선생이 오늘의\n흐름을 알려드립니다.',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
              overflow: TextOverflow.ellipsis,
              maxLines: 4,
            ),
          ],
          const SizedBox(height: 16),
          if (birthProvider.hasBirthInfo)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${birthProvider.birthInfo!.birthDate.replaceAll('-', '.')}${birthProvider.birthInfo!.hasTime ? ' ${birthProvider.birthInfo!.birthTime}' : ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () {
                if (!birthProvider.hasBirthInfo) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DailyScreen()),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.amber, size: 16),
                    SizedBox(width: 8),
                    Text('오늘의 운세 보러가기',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _shortcutCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _referralBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF8A4FFF).withValues(alpha: 0.1), const Color(0xFF6366F1).withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8A4FFF).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '친구 초대하고 티켓 받기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 4),
                const Text(
                  '추천 코드로 초대하면 양쪽 모두 3장!',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                if (_referralCode != null && !_referralLoading) ...[
                  const SizedBox(height: 8),
                  Text(
                    _referralCode!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8A4FFF),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_referralCode != null)
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _referralCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('추천 코드가 복사되었습니다!'), duration: Duration(seconds: 2)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8A4FFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('복사', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    await Share.share(
                      '운명일기에서 AI 사주 분석을 받아보세요! 추천 코드를 입력하면 티켓 3장을 드려요.\nhttps://fate.jiny.shop/ref/$_referralCode',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8A4FFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('공유', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
