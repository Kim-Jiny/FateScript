import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/birth_info.dart';
import '../providers/birth_info_provider.dart';

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

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  DateTime _selectedDate = DateTime(1990, 1, 1);
  String? _selectedTime;
  bool _timeUnknown = false;
  String _gender = 'male';
  bool _useExactTime = false;
  TimeOfDay _exactTime = const TimeOfDay(hour: 12, minute: 0);
  bool _initialized = false;

  static final _siJinValues = _siJin.map((e) => e.$2).toSet();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final info = context.read<BirthInfoProvider>().birthInfo;
      if (info != null) _prefill(info);
    }
  }

  void _prefill(BirthInfo info) {
    final parts = info.birthDate.split('-').map(int.parse).toList();
    _selectedDate = DateTime(parts[0], parts[1], parts[2]);
    _gender = info.gender;

    final time = info.birthTime;
    if (time == null || time == 'unknown') {
      _timeUnknown = true;
    } else if (_siJinValues.contains(time)) {
      _selectedTime = time;
      _useExactTime = false;
      _timeUnknown = false;
    } else {
      final tp = time.split(':').map(int.parse).toList();
      _exactTime = TimeOfDay(hour: tp[0], minute: tp[1]);
      _useExactTime = true;
      _timeUnknown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사주 정보 입력'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('생년월일'),
            const SizedBox(height: 8),
            _datePickerTile(),
            const SizedBox(height: 24),
            _sectionTitle('태어난 시간'),
            const SizedBox(height: 8),
            _timeSection(),
            const SizedBox(height: 24),
            _sectionTitle('성별'),
            const SizedBox(height: 8),
            _genderToggle(),
            const SizedBox(height: 36),
            _submitButton(),
          ],
        ),
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
            const Icon(Icons.calendar_today, size: 20, color: Color(0xFF8A4FFF)),
            const SizedBox(width: 12),
            Text(
              DateFormat('yyyy년 M월 d일').format(_selectedDate),
              style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
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

  Widget _toggleChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8A4FFF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF8A4FFF) : const Color(0xFFD1D5DB),
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
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF8A4FFF).withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? const Color(0xFF8A4FFF) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? const Color(0xFF8A4FFF) : const Color(0xFF4B5563),
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
            const Icon(Icons.access_time, size: 20, color: Color(0xFF8A4FFF)),
            const SizedBox(width: 12),
            Text(
              _exactTime.format(context),
              style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
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
            onTap: () => setState(() => _gender = 'male'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _gender == 'male' ? const Color(0xFF8A4FFF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _gender == 'male' ? const Color(0xFF8A4FFF) : const Color(0xFFD1D5DB),
                ),
              ),
              child: Center(
                child: Text(
                  '남성 (건명)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _gender == 'male' ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _gender = 'female'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _gender == 'female' ? const Color(0xFF8A4FFF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _gender == 'female' ? const Color(0xFF8A4FFF) : const Color(0xFFD1D5DB),
                ),
              ),
              child: Center(
                child: Text(
                  '여성 (곤명)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _gender == 'female' ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _submit,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFF8A4FFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('사주 분석 시작', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  void _submit() {
    String? time;
    if (_timeUnknown) {
      time = 'unknown';
    } else if (_useExactTime) {
      time =
          '${_exactTime.hour.toString().padLeft(2, '0')}:${_exactTime.minute.toString().padLeft(2, '0')}';
    } else {
      time = _selectedTime ?? 'unknown';
    }

    final info = BirthInfo(
      birthDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      birthTime: time,
      gender: _gender,
    );

    context.read<BirthInfoProvider>().save(info);
    Navigator.of(context).pop(true);
  }
}
