import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/oheng_guide.dart';
import '../models/fortune_result.dart';
import '../providers/fortune_provider.dart';
import '../widgets/oheng_chart.dart';
import 'fortune_screen.dart';

class OhengBalanceScreen extends StatelessWidget {
  const OhengBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fortuneProvider = context.watch<FortuneProvider>();
    final result = fortuneProvider.fortuneResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('오행 밸런스 가이드'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: result == null ? _noResult(context) : _content(context, result),
    );
  }

  Widget _noResult(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.balance, size: 64, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          const Text(
            '먼저 사주 분석을 받아주세요',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          const Text(
            '사주 분석 결과의 오행 데이터가 필요합니다.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FortuneScreen()),
            ),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8A4FFF)),
            child: const Text('사주 분석 받기'),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, FortuneResult result) {
    final oheng = result.oheng;
    final distribution = oheng.distribution;

    // 오행 분포에서 강한/약한 오행 찾기
    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final strongElements = sorted.where((e) => e.value > 0).take(2).map((e) => e.key).toList();
    final weakElements = sorted.reversed.where((e) => e.value <= 1).take(2).map((e) => e.key).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 오행 차트
          OhengChart(oheng: oheng),
          const SizedBox(height: 20),

          // 강한/약한 태그
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final el in strongElements)
                _tag(el, '강', const Color(0xFF22C55E)),
              for (final el in weakElements)
                _tag(el, '약', const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 24),

          // 보완 가이드
          if (weakElements.isNotEmpty) ...[
            const Text(
              '보완 가이드',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            const Text(
              '약한 오행을 보완하여 균형을 맞춰보세요.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            for (final el in weakElements)
              if (ohengGuideData.containsKey(el)) ...[
                _guideCard(ohengGuideData[el]!),
                const SizedBox(height: 12),
              ],
          ],

          if (weakElements.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Color(0xFF22C55E)),
                  SizedBox(height: 12),
                  Text('오행이 비교적 균형잡혀 있습니다!',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('현재 균형을 유지하세요.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _tag(String element, String label, Color color) {
    final guide = ohengGuideData[element];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(guide?.emoji ?? '', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$element $label',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _guideCard(OhengGuideItem guide) {
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
              Text(guide.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(guide.element,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            ],
          ),
          const SizedBox(height: 16),
          _guideRow('컬러', guide.color),
          const SizedBox(height: 8),
          _guideRow('음식', guide.food),
          const SizedBox(height: 8),
          _guideRow('방향', guide.direction),
          const SizedBox(height: 8),
          _guideRow('활동', guide.activity),
          const SizedBox(height: 8),
          _guideRow('계절', guide.season),
          const SizedBox(height: 8),
          _guideRow('숫자', guide.numbers),
        ],
      ),
    );
  }

  Widget _guideRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
        ),
      ],
    );
  }
}
