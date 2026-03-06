import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../widgets/loading_overlay.dart';
import 'input_screen.dart';

class DailyScreen extends StatelessWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final birthProvider = context.watch<BirthInfoProvider>();
    final fortuneProvider = context.watch<FortuneProvider>();

    if (!birthProvider.hasBirthInfo) {
      return _noBirthInfo(context);
    }

    final daily = fortuneProvider.dailyFortune;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: daily == null
                ? _emptyState(context, birthProvider, fortuneProvider)
                : _resultView(context, daily, fortuneProvider, birthProvider),
          ),
          if (fortuneProvider.isLoading)
            const LoadingOverlay(message: '운명선생이 오늘의 운세를 살피고 있습니다...'),
        ],
      ),
    );
  }

  Widget _noBirthInfo(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text('사주 정보를 먼저 입력해 주세요.', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InputScreen()),
              ),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8A4FFF)),
              child: const Text('사주 입력하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_outlined, size: 64, color: Color(0xFFF59E0B)),
          const SizedBox(height: 16),
          const Text('오늘의 운세', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('사주와 오늘의 일진으로 운세를 봅니다.', style: TextStyle(color: Color(0xFF6B7280))),
          if (fortuneProvider.error != null) ...[
            const SizedBox(height: 12),
            Text(fortuneProvider.error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => fortuneProvider.fetchDailyFortune(birthProvider.birthInfo!),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8A4FFF)),
            child: const Text('오늘의 운세 보기'),
          ),
        ],
      ),
    );
  }

  Widget _resultView(BuildContext context, daily, FortuneProvider fortuneProvider, BirthInfoProvider birthProvider) {
    return RefreshIndicator(
      onRefresh: () => fortuneProvider.fetchDailyFortune(birthProvider.birthInfo!),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('오늘의 운세', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daily.date,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8A4FFF)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF312E81)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('오늘의 일진', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  Text(
                    '${daily.iljinHanja} (${daily.iljinHangul})',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: MarkdownBody(
                data: daily.reading,
                styleSheet: MarkdownStyleSheet(
                  h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                  p: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF374151)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
