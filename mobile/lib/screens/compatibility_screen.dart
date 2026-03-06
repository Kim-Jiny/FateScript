import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/birth_info.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../widgets/loading_overlay.dart';
import 'input_screen.dart';

const _siJin = [
  ('자시 (23:00~01:00)', '00:00'),
  ('축시 (01:00~03:00)', '02:00'),
  ('인시 (03:00~05:00)', '04:00'),
  ('묘시 (05:00~07:00)', '06:00'),
  ('진시 (07:00~09:00)', '08:00'),
  ('사시 (09:00~11:00)', '10:00'),
  ('오시 (11:00~13:00)', '12:00'),
  ('미시 (13:00~15:00)', '14:00'),
  ('신시 (15:00~17:00)', '16:00'),
  ('유시 (17:00~19:00)', '18:00'),
  ('술시 (19:00~21:00)', '20:00'),
  ('해시 (21:00~23:00)', '22:00'),
];

const _relationships = [
  ('연인', 'lover'),
  ('배우자', 'spouse'),
  ('친구', 'friend'),
  ('동료', 'colleague'),
  ('가족', 'family'),
];

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  DateTime _selectedDate = DateTime(1990, 1, 1);
  String? _selectedTime;
  bool _timeUnknown = false;
  bool _useExactTime = false;
  TimeOfDay _exactTime = const TimeOfDay(hour: 12, minute: 0);
  String _partnerGender = 'male';
  String _relationship = 'lover';

  @override
  Widget build(BuildContext context) {
    final birthProvider = context.watch<BirthInfoProvider>();
    final fortuneProvider = context.watch<FortuneProvider>();

    if (!birthProvider.hasBirthInfo) {
      return _noBirthInfo(context);
    }

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text('궁합 분석',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      '상대방의 정보를 입력하면\n운명선생이 두 사람의 궁합을 분석해 드립니다.',
                      style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    _sectionTitle('상대방 생년월일'),
                    const SizedBox(height: 8),
                    _datePickerTile(),
                    const SizedBox(height: 24),
                    _sectionTitle('상대방 태어난 시간'),
                    const SizedBox(height: 8),
                    _timeSection(),
                    const SizedBox(height: 24),
                    _sectionTitle('상대방 성별'),
                    const SizedBox(height: 8),
                    _genderToggle(),
                    const SizedBox(height: 24),
                    _sectionTitle('관계'),
                    const SizedBox(height: 8),
                    _relationshipSelector(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: fortuneProvider.isLoading
                            ? null
                            : () => _submit(birthProvider, fortuneProvider),
                        icon: const Icon(Icons.favorite),
                        label: const Text('궁합 분석 시작'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF8A4FFF),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    if (fortuneProvider.error != null) ...[
                      const SizedBox(height: 12),
                      Text(fortuneProvider.error!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ],
                    if (fortuneProvider.compatibilityResult != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.favorite,
                                    color: Color(0xFF8A4FFF), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '운명선생의 궁합 분석',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF8A4FFF)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            MarkdownBody(
                              data: fortuneProvider
                                  .compatibilityResult!.consultation,
                              styleSheet: MarkdownStyleSheet(
                                h2: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937)),
                                p: const TextStyle(
                                    fontSize: 15,
                                    height: 1.7,
                                    color: Color(0xFF374151)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (fortuneProvider.isLoading)
            const LoadingOverlay(message: '운명선생이 궁합을 분석하고 있습니다...'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
        ),
      );

  Widget _datePickerTile() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 20, color: Color(0xFF8A4FFF)),
            const SizedBox(width: 12),
            Text(
              DateFormat('yyyy년 M월 d일').format(_selectedDate),
              style:
                  const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('ko'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Widget _timeSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _toggleChip(
                label: '시진 선택',
                selected: !_useExactTime && !_timeUnknown,
                onTap: () => setState(() {
                  _useExactTime = false;
                  _timeUnknown = false;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _toggleChip(
                label: '정확한 시간',
                selected: _useExactTime && !_timeUnknown,
                onTap: () => setState(() {
                  _useExactTime = true;
                  _timeUnknown = false;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _toggleChip(
                label: '모름',
                selected: _timeUnknown,
                onTap: () => setState(() => _timeUnknown = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_timeUnknown && !_useExactTime) _siJinGrid(),
        if (!_timeUnknown && _useExactTime) _exactTimePicker(),
      ],
    );
  }

  Widget _toggleChip(
      {required String label,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8A4FFF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF8A4FFF)
                : const Color(0xFFD1D5DB),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }

  Widget _siJinGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _siJin.map((entry) {
        final (label, value) = entry;
        final selected = _selectedTime == value;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = value),
          child: Container(
            width: (MediaQuery.of(context).size.width - 48 - 16) / 3,
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF8A4FFF).withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? const Color(0xFF8A4FFF)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF8A4FFF)
                    : const Color(0xFF4B5563),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _exactTimePicker() {
    return GestureDetector(
      onTap: _pickExactTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time,
                size: 20, color: Color(0xFF8A4FFF)),
            const SizedBox(width: 12),
            Text(
              _exactTime.format(context),
              style:
                  const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExactTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _exactTime,
    );
    if (picked != null) setState(() => _exactTime = picked);
  }

  Widget _genderToggle() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _partnerGender = 'male'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _partnerGender == 'male'
                    ? const Color(0xFF8A4FFF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _partnerGender == 'male'
                      ? const Color(0xFF8A4FFF)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: Center(
                child: Text(
                  '남성',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _partnerGender == 'male'
                        ? Colors.white
                        : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _partnerGender = 'female'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _partnerGender == 'female'
                    ? const Color(0xFF8A4FFF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _partnerGender == 'female'
                      ? const Color(0xFF8A4FFF)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: Center(
                child: Text(
                  '여성',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _partnerGender == 'female'
                        ? Colors.white
                        : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _relationshipSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _relationships.map((entry) {
        final (label, value) = entry;
        final selected = _relationship == value;
        return GestureDetector(
          onTap: () => setState(() => _relationship = value),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF8A4FFF)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? const Color(0xFF8A4FFF)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _noBirthInfo(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_outline,
                size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text('사주 정보를 먼저 입력해 주세요.',
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
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

  void _submit(
      BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    String? time;
    if (_timeUnknown) {
      time = 'unknown';
    } else if (_useExactTime) {
      time =
          '${_exactTime.hour.toString().padLeft(2, '0')}:${_exactTime.minute.toString().padLeft(2, '0')}';
    } else {
      time = _selectedTime ?? 'unknown';
    }

    final partnerInfo = BirthInfo(
      birthDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      birthTime: time,
      gender: _partnerGender,
    );

    fortuneProvider.fetchCompatibility(
        birthProvider.birthInfo!, partnerInfo, _relationship);
  }
}
