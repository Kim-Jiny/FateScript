import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/birth_info_provider.dart';
import '../services/api_service.dart';

class FortuneTrendScreen extends StatefulWidget {
  const FortuneTrendScreen({super.key});

  @override
  State<FortuneTrendScreen> createState() => _FortuneTrendScreenState();
}

class _FortuneTrendScreenState extends State<FortuneTrendScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>>? _months;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchTrend());
  }

  Future<void> _fetchTrend() async {
    final birthProvider = Provider.of<BirthInfoProvider>(context, listen: false);
    if (!birthProvider.hasBirthInfo) return;

    setState(() { _isLoading = true; _error = null; });
    try {
      final info = birthProvider.birthInfo!;
      final result = await ApiService().getFortuneTrend(
        birthDate: info.birthDate,
        birthTime: info.birthTime ?? 'unknown',
        gender: info.gender,
      );
      if (mounted) {
        setState(() {
          _months = (result['months'] as List?)?.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthProvider = context.watch<BirthInfoProvider>();

    if (!birthProvider.hasBirthInfo) {
      return Scaffold(
        appBar: AppBar(title: const Text('운세 트렌드'), backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text('사주 정보를 먼저 입력해 주세요.', style: TextStyle(color: Color(0xFF6B7280))),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('운세 트렌드'), backgroundColor: Colors.transparent, elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _months != null
                  ? _contentView()
                  : const SizedBox.shrink(),
    );
  }

  Widget _contentView() {
    if (_months == null || _months!.isEmpty) {
      return const Center(child: Text('데이터가 없습니다.'));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < _months!.length; i++) {
      final score = (_months![i]['score'] as num?)?.toDouble() ?? 50;
      spots.add(FlSpot(i.toDouble(), score));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '올해 월별 운세 흐름',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          const Text(
            '사주 오행과 각 월의 상생/상극 관계를 계산한 점수입니다.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),

          // 차트
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFFE5E7EB),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _months!.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${(_months![idx]['month'] as num?)?.toInt() ?? idx + 1}월',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 25,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF8A4FFF),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: const Color(0xFF8A4FFF),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 월별 카드
          const Text('월별 상세', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final m in _months!) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _scoreColor((m['score'] as num?)?.toInt() ?? 50).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${(m['month'] as num?)?.toInt() ?? ''}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _scoreColor((m['score'] as num?)?.toInt() ?? 50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${(m['month'] as num?)?.toInt() ?? ''}월 - ${m['pillar'] ?? ''}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                        ),
                        if (m['dominantElement'] != null)
                          Text(
                            '주요 오행: ${m['dominantElement']}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${(m['score'] as num?)?.toInt() ?? 50}점',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _scoreColor((m['score'] as num?)?.toInt() ?? 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 70) return const Color(0xFF22C55E);
    if (score >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
