import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _history = await _api.getTicketHistory();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE5),
      appBar: AppBar(
        title: const Text('티켓 사용 내역'),
        backgroundColor: const Color(0xFFF6EFE5),
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8A4FFF)))
          : _history.isEmpty
              ? const Center(
                  child: Text('티켓 내역이 없습니다.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF8A4FFF),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _HistoryCard(item: _history[i]),
                  ),
                ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String? ?? '';
    final amount = item['amount'] as int? ?? 0;
    final balanceAfter = item['balance_after'] as int? ?? 0;
    final createdAt = item['created_at'] as String? ?? '';
    final refId = item['ref_id'] as String? ?? '';

    final isPositive = amount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(type, refId),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}$amount장',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '잔액 $balanceAfter장',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type, String refId) {
    switch (type) {
      case 'purchase':
        return '티켓 구매';
      case 'consume':
        return _consumeLabel(refId);
      default:
        return type;
    }
  }

  String _consumeLabel(String refId) {
    switch (refId) {
      case 'daily':
        return '오늘의 운세';
      case 'fortune':
        return '사주 해석';
      case 'name':
        return '이름 분석';
      case 'compatibility':
        return '궁합 분석';
      default:
        return '티켓 사용';
    }
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
