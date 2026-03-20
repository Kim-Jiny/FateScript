import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/fortune_result.dart';
import '../services/api_service.dart';
import '../widgets/pillar_card.dart';
import '../widgets/oheng_chart.dart';

class ManseryeokExplorerScreen extends StatefulWidget {
  const ManseryeokExplorerScreen({super.key});

  @override
  State<ManseryeokExplorerScreen> createState() => _ManseryeokExplorerScreenState();
}

class _ManseryeokExplorerScreenState extends State<ManseryeokExplorerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _fetchManseryeok(_selectedDay);
  }

  Future<void> _fetchManseryeok(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final result = await ApiService().getManseryeok(dateStr);
      if (mounted) setState(() => _result = result);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('만세력 탐색기'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime(1920, 1, 1),
                lastDay: DateTime(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _fetchManseryeok(selectedDay);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF8A4FFF),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Color(0xFFD1D5DB),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (_result != null)
              _resultSection(),
          ],
        ),
      ),
    );
  }

  Widget _resultSection() {
    final sajuRaw = _result!['saju'] as Map<String, dynamic>?;
    final ohengRaw = _result!['oheng'] as Map<String, dynamic>?;
    final lunarRaw = _result!['lunar'] as Map<String, dynamic>?;

    if (sajuRaw == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('데이터를 불러올 수 없습니다.', style: TextStyle(color: Color(0xFF9CA3AF))),
      );
    }

    final yearPillar = SajuPillar.fromJson(sajuRaw['yearPillar'] as Map<String, dynamic>);
    final monthPillar = SajuPillar.fromJson(sajuRaw['monthPillar'] as Map<String, dynamic>);
    final dayPillar = SajuPillar.fromJson(sajuRaw['dayPillar'] as Map<String, dynamic>);

    OhengInfo? oheng;
    if (ohengRaw != null) {
      try {
        oheng = OhengInfo.fromJson(ohengRaw);
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 음력 정보
          if (lunarRaw != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF312E81)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('음력', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  Text(
                    '${lunarRaw['year']}년 ${lunarRaw['month']}월 ${lunarRaw['day']}일${lunarRaw['isLeapMonth'] == true ? ' (윤달)' : ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // 사주 기둥
          Row(
            children: [
              Expanded(child: PillarCard(label: '년주', pillar: yearPillar, oheng: oheng)),
              const SizedBox(width: 8),
              Expanded(child: PillarCard(label: '월주', pillar: monthPillar, oheng: oheng)),
              const SizedBox(width: 8),
              Expanded(child: PillarCard(label: '일주', pillar: dayPillar, oheng: oheng)),
            ],
          ),
          const SizedBox(height: 16),

          // 오행 차트
          if (oheng != null) OhengChart(oheng: oheng),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
