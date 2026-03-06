import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../models/fortune_result.dart';
import '../widgets/pillar_card.dart';
import '../widgets/oheng_chart.dart';
import '../widgets/loading_overlay.dart';
import 'input_screen.dart';

class FortuneScreen extends StatelessWidget {
  const FortuneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final birthProvider = context.watch<BirthInfoProvider>();
    final fortuneProvider = context.watch<FortuneProvider>();

    if (!birthProvider.hasBirthInfo) {
      return _noBirthInfo(context);
    }

    final result = fortuneProvider.fortuneResult;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: result == null
                ? _emptyState(context, birthProvider, fortuneProvider)
                : _resultView(context, result, fortuneProvider, birthProvider),
          ),
          if (fortuneProvider.isLoading)
            const LoadingOverlay(message: '운명선생이 사주를 분석하고 있습니다...'),
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
            const Icon(Icons.person_outline, size: 64, color: Color(0xFFD1D5DB)),
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
          const Icon(Icons.auto_awesome, size: 64, color: Color(0xFF8A4FFF)),
          const SizedBox(height: 16),
          const Text('내 사주 해석', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('전체 사주팔자를 AI가 분석합니다.', style: TextStyle(color: Color(0xFF6B7280))),
          if (fortuneProvider.error != null) ...[
            const SizedBox(height: 12),
            Text(fortuneProvider.error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => fortuneProvider.fetchFortune(birthProvider.birthInfo!),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8A4FFF)),
            child: const Text('사주 분석 시작'),
          ),
        ],
      ),
    );
  }

  Widget _resultView(BuildContext context, FortuneResult result, FortuneProvider fortuneProvider, BirthInfoProvider birthProvider) {
    return RefreshIndicator(
      onRefresh: () => fortuneProvider.fetchFortune(birthProvider.birthInfo!),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('내 사주팔자', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: PillarCard(label: '년주', pillar: result.yearPillar, oheng: result.oheng)),
                const SizedBox(width: 8),
                Expanded(child: PillarCard(label: '월주', pillar: result.monthPillar, oheng: result.oheng)),
                const SizedBox(width: 8),
                Expanded(child: PillarCard(label: '일주', pillar: result.dayPillar, oheng: result.oheng)),
                const SizedBox(width: 8),
                Expanded(
                  child: result.hourPillar != null
                      ? PillarCard(label: '시주', pillar: result.hourPillar!, oheng: result.oheng)
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Column(
                            children: [
                              Text('시주', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF8A4FFF))),
                              SizedBox(height: 10),
                              Text('?', style: TextStyle(fontSize: 24, color: Color(0xFFD1D5DB))),
                              Text('미상', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                            ],
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OhengChart(oheng: result.oheng),
            const SizedBox(height: 20),
            // 전체 개요
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: MarkdownBody(
                data: result.interpretation,
                styleSheet: MarkdownStyleSheet(
                  h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                  p: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF374151)),
                ),
              ),
            ),
            // 분야별 카테고리 카드
            // ignore: unnecessary_cast — 이전 캐시 데이터에서 categories가 null일 수 있음
            for (final category in (result.categories as List<FortuneCategory>?) ?? const <FortuneCategory>[]) ...[
              const SizedBox(height: 16),
              _categoryCard(category),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(FortuneCategory category) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 19)),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarkdownBody(
            data: category.content,
            styleSheet: MarkdownStyleSheet(
              h2: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
              p: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }
}
