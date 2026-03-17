import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/birth_info.dart';
import '../models/compatibility_history_item.dart';
import '../providers/auth_provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../providers/ticket_provider.dart';
import '../services/api_service.dart';
import '../widgets/loading_overlay.dart';
import 'input_screen.dart';
import 'login_screen.dart';

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
  bool _showNewAnalysis = false;
  DateTime _selectedDate = DateTime(1990, 1, 1);
  String? _selectedTime;
  bool _timeUnknown = false;
  bool _useExactTime = false;
  TimeOfDay _exactTime = const TimeOfDay(hour: 12, minute: 0);
  String _partnerGender = 'male';
  String _relationship = 'lover';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final fortuneProvider =
        Provider.of<FortuneProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      fortuneProvider.loadCompatibilityHistory(fromServer: true);
    } else {
      fortuneProvider.loadCompatibilityHistory(fromServer: false);
    }
  }

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
          SafeArea(
            child: _showNewAnalysis
                ? _newAnalysisView(birthProvider, fortuneProvider)
                : _historyView(fortuneProvider),
          ),
          if (fortuneProvider.isLoading)
            const LoadingOverlay(
                message: '운명선생이 궁합을 분석하고 있습니다...'),
        ],
      ),
    );
  }

  Widget _historyView(FortuneProvider fortuneProvider) {
    final history = fortuneProvider.compatibilityHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              const Text('궁합 분석',
                  style:
                      TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => setState(() => _showNewAnalysis = true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('새 궁합 분석'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8A4FFF),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: history.isEmpty
              ? _emptyHistory()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: history.length,
                  itemBuilder: (context, index) =>
                      _historyCard(context, history[index], fortuneProvider),
                ),
        ),
      ],
    );
  }

  Widget _emptyHistory() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_outline,
              size: 64, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          const Text(
            '아직 궁합 분석 기록이 없습니다.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          const Text(
            '새 궁합 분석을 시작해 보세요.',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(BuildContext context, CompatibilityHistoryItem item,
      FortuneProvider fortuneProvider) {
    return GestureDetector(
      onTap: () => _showHistoryDetail(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                const Icon(Icons.favorite,
                    size: 16, color: Color(0xFF8A4FFF)),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.relationshipLabel,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A4FFF)),
                  ),
                ),
                const Spacer(),
                if (item.createdAt.isNotEmpty)
                  Text(
                    _formatDate(item.createdAt),
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF9CA3AF)),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () =>
                      _confirmDelete(context, item.id, fortuneProvider),
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _personChip(
                    '나',
                    item.myBirthDate,
                    item.myGender == 'male' ? '남' : '여',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.sync_alt,
                      size: 16, color: Color(0xFF9CA3AF)),
                ),
                Expanded(
                  child: _personChip(
                    '상대',
                    item.partnerBirthDate,
                    item.partnerGender == 'male' ? '남' : '여',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _personChip(String label, String birthDate, String gender) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280))),
          const SizedBox(height: 2),
          Text(
            '$birthDate ($gender)',
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('yyyy.MM.dd').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  void _showHistoryDetail(
      BuildContext context, CompatibilityHistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.favorite,
                            color: Color(0xFF8A4FFF), size: 20),
                        SizedBox(width: 8),
                        Text(
                          '운명선생의 궁합 분석',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8A4FFF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MarkdownBody(
                      data: item.consultation,
                      styleSheet: MarkdownStyleSheet(
                        h2: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937)),
                        p: const TextStyle(
                            fontSize: 13,
                            height: 1.7,
                            color: Color(0xFF374151)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, int id, FortuneProvider fortuneProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('궁합 기록 삭제'),
        content: const Text('이 궁합 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              fortuneProvider.deleteCompatibilityHistoryItem(
                  id, authProvider.isLoggedIn);
              Navigator.pop(context);
            },
            child:
                const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── 새 궁합 분석 ──

  Widget _newAnalysisView(
      BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _showNewAnalysis = false);
                    _loadHistory();
                  },
                  child: const Icon(Icons.arrow_back_ios, size: 20),
                ),
                const SizedBox(width: 8),
                const Text('새 궁합 분석',
                    style: TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '상대방의 정보를 입력하면\n운명선생이 두 사람의 궁합을 분석해 드립니다.',
              style: TextStyle(
                  fontSize: 12,
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
                  style:
                      const TextStyle(color: Colors.red, fontSize: 11)),
            ],
            if (fortuneProvider.compatibilityResult != null) ...[
              const SizedBox(height: 24),
              Container(
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
                        Icon(Icons.favorite,
                            color: Color(0xFF8A4FFF), size: 20),
                        SizedBox(width: 8),
                        Text(
                          '운명선생의 궁합 분석',
                          style: TextStyle(
                              fontSize: 14,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937)),
                        p: const TextStyle(
                            fontSize: 13,
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

  Widget _datePickerTile() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF1F2937)),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  selected ? Colors.white : const Color(0xFF4B5563),
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
            width:
                (MediaQuery.of(context).size.width - 48 - 16) / 3,
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 6),
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
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF1F2937)),
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
                    fontSize: 13,
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
                    fontSize: 13,
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
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : const Color(0xFF4B5563),
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
                style: TextStyle(
                    fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const InputScreen()),
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
      BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (result != true) return;
    }

    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    try {
      await ticketProvider.consumeTicket('compatibility');
    } on InsufficientTicketsException {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('티켓 부족'),
            content: const Text('사주 티켓이 부족합니다.\n마이페이지에서 티켓을 구매해 주세요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
      return;
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

    final partnerInfo = BirthInfo(
      birthDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      birthTime: time,
      gender: _partnerGender,
    );

    if (!mounted) return;
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    fortuneProvider.fetchCompatibility(
        birthProvider.birthInfo!, partnerInfo, _relationship,
        isLoggedIn: authProv.isLoggedIn);
  }
}
