import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/ticket_provider.dart';
import '../services/api_service.dart';
import '../widgets/loading_overlay.dart';
import 'login_screen.dart';

const _eventTypes = [
  ('이사', 'move'),
  ('결혼', 'wedding'),
  ('개업', 'business'),
  ('여행', 'travel'),
  ('면접', 'interview'),
];

class AuspiciousDateScreen extends StatefulWidget {
  const AuspiciousDateScreen({super.key});

  @override
  State<AuspiciousDateScreen> createState() => _AuspiciousDateScreenState();
}

class _AuspiciousDateScreenState extends State<AuspiciousDateScreen> {
  String _eventType = 'move';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  Widget build(BuildContext context) {
    final birthProvider = context.watch<BirthInfoProvider>();

    if (!birthProvider.hasBirthInfo) {
      return Scaffold(
        appBar: AppBar(title: const Text('택일/길일추천'), backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text('사주 정보를 먼저 입력해 주세요.', style: TextStyle(color: Color(0xFF6B7280))),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('택일/길일추천'), backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('어떤 행사인가요?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _eventTypes.map((e) {
                    final selected = _eventType == e.$2;
                    return ChoiceChip(
                      label: Text(e.$1),
                      selected: selected,
                      selectedColor: const Color(0xFF8A4FFF).withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _eventType = e.$2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text('날짜 범위', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _dateTile('시작', _startDate, (d) => setState(() => _startDate = d))),
                    const SizedBox(width: 12),
                    Expanded(child: _dateTile('종료', _endDate, (d) => setState(() => _endDate = d))),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : () => _submit(birthProvider),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8A4FFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('길일 찾기 (1티켓)'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  _resultView(),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            const LoadingOverlay(message: '운명선생이 길일을 찾고 있습니다...'),
        ],
      ),
    );
  }

  Widget _dateTile(String label, DateTime date, ValueChanged<DateTime> onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('ko'),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8A4FFF)),
            const SizedBox(width: 8),
            Text(
              DateFormat('yyyy.MM.dd').format(date),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BirthInfoProvider birthProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (result != true) return;
    }

    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    try {
      await ticketProvider.consumeTicket('auspicious_date');
    } on InsufficientTicketsException {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('티켓 부족'),
            content: const Text('티켓이 부족합니다. (필요: 1장)\n마이페이지에서 티켓을 구매해 주세요.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
          ),
        );
      }
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final info = birthProvider.birthInfo!;
      final result = await ApiService().getAuspiciousDate(
        birthDate: info.birthDate,
        birthTime: info.birthTime ?? 'unknown',
        gender: info.gender,
        eventType: _eventType,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _resultView() {
    final dates = (_result!['dates'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final advice = _result!['advice'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('추천 길일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        for (int i = 0; i < dates.length; i++) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}위',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8A4FFF)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      dates[i]['date'] ?? '',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                    ),
                    const Spacer(),
                    Text(
                      '${dates[i]['score'] ?? 0}점',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF8A4FFF)),
                    ),
                  ],
                ),
                if (dates[i]['pillar'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '일진: ${dates[i]['pillar']}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
                if (dates[i]['reason'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    dates[i]['reason'],
                    style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.6),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (advice.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: MarkdownBody(
              data: advice,
              styleSheet: MarkdownStyleSheet(
                h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                p: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF374151)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
