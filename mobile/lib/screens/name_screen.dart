import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/hanja_dict.dart';
import '../models/birth_info.dart';
import '../models/name_analysis_result.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../widgets/hanja_selector.dart';
import '../widgets/loading_overlay.dart';

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

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  bool _isRecommendMode = false;
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  Map<int, HanjaEntry> _selectedHanja = {};

  // 생년월일 입력 관련
  bool _useSavedSaju = true;
  DateTime _selectedDate = DateTime(1990, 1, 1);
  String? _selectedTime;
  bool _timeUnknown = false;
  bool _useExactTime = false;
  TimeOfDay _exactTime = const TimeOfDay(hour: 12, minute: 0);
  String _gender = 'male';

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    setState(() => _selectedHanja = {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final birthProvider = context.watch<BirthInfoProvider>();
    final fortuneProvider = context.watch<FortuneProvider>();

    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text('성명학',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _toggleChip(
                            label: '이름 해석',
                            selected: !_isRecommendMode,
                            onTap: () =>
                                setState(() => _isRecommendMode = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _toggleChip(
                            label: '이름 추천',
                            selected: _isRecommendMode,
                            onTap: () =>
                                setState(() => _isRecommendMode = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isRecommendMode
                        ? _recommendTab(birthProvider, fortuneProvider)
                        : _analyzeTab(birthProvider, fortuneProvider),
                  ),
                ],
              ),
            ),
          ),
          if (fortuneProvider.isLoading)
            LoadingOverlay(
              message: _isRecommendMode
                  ? '운명선생이 이름을 추천하고 있습니다...'
                  : '운명선생이 이름을 분석하고 있습니다...',
            ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
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
              color: selected ? Colors.white : const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // ── 생년월일 입력 섹션 (공통) ──

  Widget _birthInfoSection(BirthInfoProvider birthProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('생년월일 정보'),
        const SizedBox(height: 8),
        if (birthProvider.hasBirthInfo) ...[
          Row(
            children: [
              Expanded(
                child: _toggleChip(
                  label: '내 사주 사용',
                  selected: _useSavedSaju,
                  onTap: () => setState(() => _useSavedSaju = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _toggleChip(
                  label: '직접 입력',
                  selected: !_useSavedSaju,
                  onTap: () => setState(() => _useSavedSaju = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_useSavedSaju)
            _savedSajuCard(birthProvider)
          else
            _manualBirthInput(),
        ] else ...[
          _manualBirthInput(),
        ],
      ],
    );
  }

  Widget _savedSajuCard(BirthInfoProvider birthProvider) {
    final info = birthProvider.birthInfo!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF8A4FFF).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8A4FFF).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF8A4FFF), size: 18),
          const SizedBox(width: 10),
          Text(
            '${info.birthDate}  ${info.hasTime ? info.birthTime! : '시간 미상'}  ${info.gender == 'male' ? '남성' : '여성'}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }

  Widget _manualBirthInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _datePickerTile(),
        const SizedBox(height: 16),
        _sectionTitle('태어난 시간'),
        const SizedBox(height: 8),
        _timeSection(),
        const SizedBox(height: 16),
        _sectionTitle('성별'),
        const SizedBox(height: 8),
        _genderToggle(),
      ],
    );
  }

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
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
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
                fontSize: 10,
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
            const Icon(Icons.access_time, size: 20, color: Color(0xFF8A4FFF)),
            const SizedBox(width: 12),
            Text(
              _exactTime.format(context),
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
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
                color: _gender == 'male'
                    ? const Color(0xFF8A4FFF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _gender == 'male'
                      ? const Color(0xFF8A4FFF)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: Center(
                child: Text(
                  '남성',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _gender == 'male'
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
            onTap: () => setState(() => _gender = 'female'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _gender == 'female'
                    ? const Color(0xFF8A4FFF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _gender == 'female'
                      ? const Color(0xFF8A4FFF)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: Center(
                child: Text(
                  '여성',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _gender == 'female'
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

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
        ),
      );

  BirthInfo _getEffectiveBirthInfo(BirthInfoProvider birthProvider) {
    if (_useSavedSaju && birthProvider.hasBirthInfo) {
      return birthProvider.birthInfo!;
    }

    String? time;
    if (_timeUnknown) {
      time = 'unknown';
    } else if (_useExactTime) {
      time =
          '${_exactTime.hour.toString().padLeft(2, '0')}:${_exactTime.minute.toString().padLeft(2, '0')}';
    } else {
      time = _selectedTime ?? 'unknown';
    }

    return BirthInfo(
      birthDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      birthTime: time,
      gender: _gender,
    );
  }

  // ── 이름 해석 탭 ──

  Widget _analyzeTab(
      BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이름과 한자를 입력하면 사주와의 궁합을 분석합니다.\n획수, 오행, 음양을 종합적으로 평가합니다.',
            style: TextStyle(
                fontSize: 12, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 20),
          _sectionTitle('이름'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '한글 이름 (예: 홍길동)',
                hintStyle: TextStyle(color: Color(0xFFD1D5DB)),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          if (_nameController.text.trim().isNotEmpty)
            HanjaSelector(
              name: _nameController.text.trim(),
              selectedHanja: _selectedHanja,
              onChanged: (updated) => setState(() => _selectedHanja = updated),
            ),
          const SizedBox(height: 20),
          _birthInfoSection(birthProvider),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: fortuneProvider.isLoading
                  ? null
                  : () => _submitAnalyze(birthProvider, fortuneProvider),
              icon: const Icon(Icons.text_fields),
              label: const Text('이름 분석하기'),
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
                style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],
          if (fortuneProvider.nameAnalysisResult != null) ...[
            const SizedBox(height: 24),
            _analysisResultCard(fortuneProvider.nameAnalysisResult!),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _analysisResultCard(NameAnalysisResult result) {
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
              const Icon(Icons.text_fields,
                  color: Color(0xFF8A4FFF), size: 20),
              const SizedBox(width: 8),
              const Text(
                '이름 분석 결과',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A4FFF)),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${result.overallScore}점',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A4FFF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result.characters.isNotEmpty) ...[
            const Text('글자별 분석',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            ...result.characters.map(_characterCard),
            const SizedBox(height: 16),
          ],
          _markdownSection('오행 균형', result.ohengBalance),
          const SizedBox(height: 12),
          _markdownSection('음양 균형', result.yinYangBalance),
          const SizedBox(height: 12),
          _markdownSection('사주 궁합', result.sajuCompatibility),
          if (result.strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('강점',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            ...result.strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('  $s',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
                          height: 1.5)),
                )),
          ],
          if (result.cautions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('주의점',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            ...result.cautions.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('  $c',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF374151),
                          height: 1.5)),
                )),
          ],
          const SizedBox(height: 16),
          _markdownSection('운명선생의 조언', result.advice),
        ],
      ),
    );
  }

  Widget _characterCard(NameCharacter ch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(ch.char,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          if (ch.hanja != null) ...[
            const SizedBox(width: 8),
            Text('(${ch.hanja})',
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF6B7280))),
          ],
          const Spacer(),
          _tag('${ch.strokes}획'),
          const SizedBox(width: 6),
          _tag(ch.oheng),
          const SizedBox(width: 6),
          _tag(ch.yinYang),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A4FFF))),
    );
  }

  Widget _markdownSection(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937))),
        const SizedBox(height: 4),
        MarkdownBody(
          data: content,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
                fontSize: 12, height: 1.7, color: Color(0xFF374151)),
          ),
        ),
      ],
    );
  }

  // ── 이름 추천 탭 ──

  Widget _recommendTab(
      BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '성(姓)을 입력하면 사주에 맞는 이름을 추천합니다.',
            style: TextStyle(
                fontSize: 12, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 20),
          _sectionTitle('성(姓)'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                hintText: '성을 입력하세요 (예: 김)',
                hintStyle: TextStyle(color: Color(0xFFD1D5DB)),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          _birthInfoSection(birthProvider),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: fortuneProvider.isLoading
                  ? null
                  : () => _submitRecommend(birthProvider, fortuneProvider),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('이름 추천받기'),
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
                style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],
          if (fortuneProvider.nameRecommendResult != null) ...[
            const SizedBox(height: 24),
            _recommendResultCard(fortuneProvider.nameRecommendResult!),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _recommendResultCard(NameRecommendResult result) {
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
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF8A4FFF), size: 20),
              SizedBox(width: 8),
              Text(
                '추천 이름',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A4FFF)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...result.recommendations.map((r) => _recommendationCard(r)),
          if (result.selectionCriteria.isNotEmpty) ...[
            const SizedBox(height: 12),
            _markdownSection('선정 기준', result.selectionCriteria),
          ],
          if (result.advice.isNotEmpty) ...[
            const SizedBox(height: 12),
            _markdownSection('운명선생의 조언', result.advice),
          ],
        ],
      ),
    );
  }

  Widget _recommendationCard(NameRecommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(rec.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('(${rec.hanja})',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280))),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${rec.score}점',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A4FFF))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(rec.meaning,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF374151), height: 1.5)),
          const SizedBox(height: 4),
          Text(rec.sajuFit,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B7280), height: 1.4)),
        ],
      ),
    );
  }

  // ── 제출 ──

  void _submitAnalyze(
      BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해 주세요.')),
      );
      return;
    }

    // 선택된 한자로 한자 이름 구성
    String fullName = name;
    if (_selectedHanja.isNotEmpty) {
      final chars = name.characters.toList();
      final hanjaChars = List.generate(chars.length, (i) {
        final entry = _selectedHanja[i];
        return entry?.hanja ?? chars[i];
      });
      fullName = '$name(${hanjaChars.join()})';
    }

    final info = _getEffectiveBirthInfo(birthProvider);
    fortuneProvider.analyzeName(info, fullName);
  }

  void _submitRecommend(
      BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    final lastName = _lastNameController.text.trim();
    if (lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성을 입력해 주세요.')),
      );
      return;
    }
    final info = _getEffectiveBirthInfo(birthProvider);
    fortuneProvider.recommendNames(info, lastName);
  }
}
