import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../providers/ticket_provider.dart';
import '../models/fortune_result.dart';
import '../services/api_service.dart';
import '../widgets/pillar_card.dart';
import '../widgets/oheng_chart.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/share_button.dart';
import '../widgets/pdf_button.dart';
import 'input_screen.dart';
import 'login_screen.dart';

class FortuneScreen extends StatefulWidget {
  const FortuneScreen({super.key});

  @override
  State<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends State<FortuneScreen> {
  final Set<String> _expanded = {'manseryeok'};

  @override
  Widget build(BuildContext context) {
    final birthProvider = context.watch<BirthInfoProvider>();
    final fortuneProvider = context.watch<FortuneProvider>();

    if (!birthProvider.hasBirthInfo) {
      return _noBirthInfo(context);
    }

    final result = fortuneProvider.fortuneResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 사주'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          result == null
              ? _emptyState(context, birthProvider, fortuneProvider)
              : _resultView(context, result, fortuneProvider, birthProvider),
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
            const Icon(Icons.person_outline,
                size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text('사주 정보를 먼저 입력해 주세요.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InputScreen()),
              ),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8A4FFF)),
              child: const Text('사주 입력하기'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchWithTicket(BuildContext context, BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) async {
    if (fortuneProvider.isLoading) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (result != true) return;
    }

    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    // 이미 캐시된 결과가 있으면 티켓 미소모
    if (fortuneProvider.fortuneResult != null) {
      await fortuneProvider.clearSavedFortune();
      if (context.mounted) {
        await fortuneProvider.fetchFortune(birthProvider.birthInfo!);
      }
      return;
    }

    try {
      await fortuneProvider.fetchFortune(birthProvider.birthInfo!, consumeTicket: true);
      ticketProvider.syncBalanceFromApi();
    } on InsufficientTicketsException {
      if (context.mounted) _showInsufficientDialog(context);
      return;
    }
  }

  void _showInsufficientDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('티켓 부족'),
        content: const Text('티켓이 부족합니다. (필요: 1장)\n마이페이지에서 티켓을 구매해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, BirthInfoProvider birthProvider,
      FortuneProvider fortuneProvider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 64, color: Color(0xFF8A4FFF)),
          const SizedBox(height: 16),
          const Text('내 사주 해석',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('전체 사주팔자를 AI가 분석합니다.',
              style: TextStyle(color: Color(0xFF6B7280))),
          if (fortuneProvider.error != null) ...[
            const SizedBox(height: 12),
            Text(fortuneProvider.error!,
                style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () =>
                _fetchWithTicket(context, birthProvider, fortuneProvider),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8A4FFF)),
            child: const Text('사주 분석 시작 (1티켓)'),
          ),
        ],
      ),
    );
  }

  Widget _resultView(BuildContext context, FortuneResult result,
      FortuneProvider fortuneProvider, BirthInfoProvider birthProvider) {
    // 만세력 내용 결정 (새 필드 우선, 이전 캐시 호환)
    final manseryeokContent =
        result.manseryeok.isNotEmpty ? result.manseryeok : result.interpretation;

    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('내 사주팔자',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                const Spacer(),
                PdfButton(
                  type: 'fortune',
                  data: result.toJson(),
                ),
                const SizedBox(width: 12),
                ShareButton(
                  type: 'fortune',
                  data: result.toJson(),
                  birthDate: birthProvider.birthInfo?.birthDate,
                  birthTime: birthProvider.birthInfo?.birthTime,
                  gender: birthProvider.birthInfo?.gender,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 사주 기둥
            Row(
              children: [
                Expanded(
                    child: PillarCard(
                        label: '년주',
                        pillar: result.yearPillar,
                        oheng: result.oheng)),
                const SizedBox(width: 8),
                Expanded(
                    child: PillarCard(
                        label: '월주',
                        pillar: result.monthPillar,
                        oheng: result.oheng)),
                const SizedBox(width: 8),
                Expanded(
                    child: PillarCard(
                        label: '일주',
                        pillar: result.dayPillar,
                        oheng: result.oheng)),
                const SizedBox(width: 8),
                Expanded(
                  child: result.hourPillar != null
                      ? PillarCard(
                          label: '시주',
                          pillar: result.hourPillar!,
                          oheng: result.oheng)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Column(
                            children: [
                              Text('시주',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF8A4FFF))),
                              SizedBox(height: 10),
                              Text('?',
                                  style: TextStyle(
                                      fontSize: 24,
                                      color: Color(0xFFD1D5DB))),
                              Text('미상',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9CA3AF))),
                            ],
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 오행 차트
            OhengChart(oheng: result.oheng),
            const SizedBox(height: 16),

            // 만세력 풀이
            if (manseryeokContent.isNotEmpty)
              _expandableSection(
                key: 'manseryeok',
                emoji: '📜',
                title: '만세력 풀이',
                content: manseryeokContent,
              ),

            // 올해의 운세
            if (result.yearFortune.isNotEmpty) ...[
              const SizedBox(height: 12),
              _expandableSection(
                key: 'yearFortune',
                emoji: '🌟',
                title: '올해의 운세',
                content: result.yearFortune,
              ),
            ],

            // 카테고리별
            for (final category
                in (result.categories as List<FortuneCategory>?) ??
                    const <FortuneCategory>[]) ...[
              const SizedBox(height: 12),
              _expandableSection(
                key: category.key,
                emoji: category.emoji,
                title: category.label,
                content: category.content,
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
    );
  }

  Widget _expandableSection({
    required String key,
    required String emoji,
    required String title,
    required String content,
  }) {
    final isExpanded = _expanded.contains(key);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expanded.remove(key);
                } else {
                  _expanded.add(key);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 19)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 22, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937)),
                  h2: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937)),
                  h3: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151)),
                  p: const TextStyle(
                      fontSize: 13,
                      height: 1.7,
                      color: Color(0xFF374151)),
                  listBullet: const TextStyle(
                      fontSize: 13, color: Color(0xFF374151)),
                ),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}
