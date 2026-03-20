import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import 'daily_screen.dart';
import 'fortune_screen.dart';
import 'name_screen.dart';
import 'auspicious_date_screen.dart';
import 'manseryeok_explorer_screen.dart';
import 'oheng_balance_screen.dart';
import 'fortune_trend_screen.dart';

class SajuHubScreen extends StatelessWidget {
  const SajuHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '사주',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI 사주 분석의 모든 기능을 만나보세요.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  FeatureCard(
                    icon: Icons.wb_sunny,
                    title: '오늘의 운세',
                    subtitle: '1티켓',
                    color: const Color(0xFFF59E0B),
                    onTap: () => _push(context, const DailyScreen()),
                  ),
                  FeatureCard(
                    icon: Icons.auto_awesome,
                    title: '사주 분석',
                    subtitle: '3티켓',
                    color: const Color(0xFF8A4FFF),
                    onTap: () => _push(context, const FortuneScreen()),
                  ),
                  FeatureCard(
                    icon: Icons.text_fields,
                    title: '성명학',
                    subtitle: '1~2티켓',
                    color: const Color(0xFF3B82F6),
                    onTap: () => _push(context, const NameScreen()),
                  ),
                  FeatureCard(
                    icon: Icons.calendar_month,
                    title: '택일/길일추천',
                    subtitle: '2티켓',
                    color: const Color(0xFFEF4444),
                    onTap: () => _push(context, const AuspiciousDateScreen()),
                  ),
                  FeatureCard(
                    icon: Icons.table_chart,
                    title: '만세력 탐색기',
                    subtitle: '무료',
                    color: const Color(0xFF22C55E),
                    onTap: () => _push(context, const ManseryeokExplorerScreen()),
                  ),
                  FeatureCard(
                    icon: Icons.balance,
                    title: '오행 밸런스',
                    subtitle: '무료',
                    color: const Color(0xFFF59E0B),
                    onTap: () => _push(context, const OhengBalanceScreen()),
                  ),
                  FeatureCard(
                    icon: Icons.show_chart,
                    title: '운세 트렌드',
                    subtitle: '무료',
                    color: const Color(0xFF6366F1),
                    onTap: () => _push(context, const FortuneTrendScreen()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
