import 'dart:convert';
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

const _siJinTeam = [
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

const _relationshipLabels = {
  'team': '팀/프로젝트',
  'friends': '친구 모임',
  'family': '가족',
  'business': '비즈니스',
};

class TeamCompatibilityView extends StatefulWidget {
  const TeamCompatibilityView({super.key});

  @override
  State<TeamCompatibilityView> createState() => _TeamCompatibilityViewState();
}

class _TeamCompatibilityViewState extends State<TeamCompatibilityView> {
  bool _showNewAnalysis = false;
  List<Map<String, dynamic>> _history = [];
  bool _historyLoading = false;

  // 새 분석 폼 상태
  final List<_MemberData> _members = [
    _MemberData(),
    _MemberData(),
    _MemberData(),
  ];
  String _relationship = 'team';
  bool _isLoading = false;
  String? _error;
  String? _result;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) return;
    setState(() => _historyLoading = true);
    try {
      final list = await ApiService().getTeamCompatibilityHistory();
      if (mounted) setState(() => _history = list);
    } catch (_) {
      // 조회 실패 시 빈 리스트 유지
    } finally {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  void _prefillMyInfo() {
    final birthProvider = Provider.of<BirthInfoProvider>(context, listen: false);
    if (birthProvider.hasBirthInfo) {
      final info = birthProvider.birthInfo!;
      final me = _members[0];
      final parts = info.birthDate.split('-');
      if (parts.length == 3) {
        me.birthDate = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]),
        );
      }
      me.gender = info.gender;
      if (info.hasTime) {
        final timeParts = info.birthTime!.split(':');
        if (timeParts.length == 2) {
          final h = int.tryParse(timeParts[0]) ?? 0;
          final m = int.tryParse(timeParts[1]) ?? 0;
          final siJinMatch = _siJinTeam.where((e) => e.$2 == info.birthTime).firstOrNull;
          if (siJinMatch != null) {
            me.selectedSiJin = siJinMatch.$2;
            me.useExactTime = false;
            me.timeUnknown = false;
          } else {
            me.exactTime = TimeOfDay(hour: h, minute: m);
            me.useExactTime = true;
            me.timeUnknown = false;
          }
        }
      }
    }
  }

  static const _relationships = [
    ('팀/프로젝트', 'team'),
    ('친구 모임', 'friends'),
    ('가족', 'family'),
    ('비즈니스', 'business'),
  ];

  @override
  Widget build(BuildContext context) {
    if (_showNewAnalysis) return _newAnalysisView();
    return _historyView();
  }

  // ── 히스토리 뷰 ──

  Widget _historyView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              const Text('팀 궁합',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  _resetForm();
                  _prefillMyInfo();
                  setState(() => _showNewAnalysis = true);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('새 팀 분석'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8A4FFF),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _historyLoading
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
                  ? _emptyHistory()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _history.length,
                      itemBuilder: (context, index) => _historyCard(_history[index]),
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
          const Icon(Icons.groups_outlined, size: 64, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          const Text(
            '아직 팀 궁합 분석 기록이 없습니다.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          const Text(
            '새 팀 분석을 시작해 보세요.',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(Map<String, dynamic> item) {
    final id = item['id'] as int;
    final members = _parseJsonList(item['members'])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final relationship = item['relationship'] as String? ?? '';
    final createdAt = item['created_at'] as String? ?? '';

    final memberNames = members.map((m) {
      final name = m['name'] as String?;
      return (name != null && name.isNotEmpty) ? name : '멤버';
    }).toList();

    return GestureDetector(
      onTap: () => _showHistoryDetail(item),
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
                const Icon(Icons.groups, size: 16, color: Color(0xFF8A4FFF)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _relationshipLabels[relationship] ?? relationship,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF8A4FFF)),
                  ),
                ),
                const Spacer(),
                if (createdAt.isNotEmpty)
                  Text(
                    _formatDate(createdAt),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDelete(id),
                  child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              memberNames.join(', '),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${members.length}명',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _parseJsonList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is String) {
      try { return jsonDecode(raw) as List; } catch (_) {}
    }
    return [];
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('yyyy.MM.dd').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  void _showHistoryDetail(Map<String, dynamic> item) {
    final result = item['result'];
    String consultation = '';
    if (result is Map) {
      consultation = result['consultation'] as String? ?? '';
    } else if (result is String) {
      try {
        final parsed = jsonDecode(result) as Map<String, dynamic>;
        consultation = parsed['consultation'] as String? ?? '';
      } catch (_) {
        consultation = result;
      }
    }

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
                    Row(
                      children: [
                        const Icon(Icons.groups, color: Color(0xFF8A4FFF), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '운명선생의 팀 궁합 분석',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8A4FFF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    MarkdownBody(
                      data: consultation,
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

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('팀 궁합 기록 삭제'),
        content: const Text('이 팀 궁합 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService().deleteTeamCompatibilityHistory(id);
                if (mounted) {
                  setState(() => _history.removeWhere((e) => e['id'] == id));
                }
              } catch (_) {}
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _members.clear();
    _members.addAll([_MemberData(), _MemberData(), _MemberData()]);
    _relationship = 'team';
    _error = null;
    _result = null;
  }

  // ── 새 분석 뷰 ──

  Widget _newAnalysisView() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          SingleChildScrollView(
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
                    const Text('새 팀 분석',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('팀 멤버 (3~6명)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                for (int i = 0; i < _members.length; i++) ...[
                  _memberCard(i),
                  const SizedBox(height: 10),
                ],
                if (_members.length < 6)
                  TextButton.icon(
                    onPressed: () => setState(() => _members.add(_MemberData())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('멤버 추가'),
                  ),
                const SizedBox(height: 20),
                const Text('관계 유형', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _relationships.map((e) {
                    final selected = _relationship == e.$2;
                    return ChoiceChip(
                      label: Text(e.$1),
                      selected: selected,
                      selectedColor: const Color(0xFF8A4FFF).withValues(alpha: 0.15),
                      onSelected: (_) => setState(() => _relationship = e.$2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: const Icon(Icons.group),
                    label: const Text('팀 궁합 분석 (1티켓)'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8A4FFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: MarkdownBody(
                      data: _result!,
                      styleSheet: MarkdownStyleSheet(
                        h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                        p: const TextStyle(fontSize: 13, height: 1.7, color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            const LoadingOverlay(message: '운명선생이 팀 궁합을 분석하고 있습니다...'),
        ],
      ),
    );
  }

  Widget _memberCard(int index) {
    final member = _members[index];
    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(index == 0 ? '멤버 1 (나)' : '멤버 ${index + 1}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8A4FFF))),
              const Spacer(),
              if (_members.length > 3)
                GestureDetector(
                  onTap: () => setState(() => _members.removeAt(index)),
                  child: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: '이름 (선택)',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => member.name = v,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: member.birthDate,
                firstDate: DateTime(1920),
                lastDate: DateTime.now(),
                locale: const Locale('ko'),
              );
              if (picked != null) setState(() => member.birthDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Color(0xFF8A4FFF)),
                  const SizedBox(width: 8),
                  Text(DateFormat('yyyy-MM-dd').format(member.birthDate),
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => member.gender = 'male'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: member.gender == 'male' ? const Color(0xFF8A4FFF) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: member.gender == 'male' ? const Color(0xFF8A4FFF) : const Color(0xFFD1D5DB),
                      ),
                    ),
                    child: Center(
                      child: Text('남성', style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: member.gender == 'male' ? Colors.white : const Color(0xFF4B5563),
                      )),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => member.gender = 'female'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: member.gender == 'female' ? const Color(0xFF8A4FFF) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: member.gender == 'female' ? const Color(0xFF8A4FFF) : const Color(0xFFD1D5DB),
                      ),
                    ),
                    child: Center(
                      child: Text('여성', style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: member.gender == 'female' ? Colors.white : const Color(0xFF4B5563),
                      )),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _timeSelector(member),
        ],
      ),
    );
  }

  Widget _timeSelector(_MemberData member) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _timeChip('시진', !member.useExactTime && !member.timeUnknown, () {
              setState(() { member.useExactTime = false; member.timeUnknown = false; });
            })),
            const SizedBox(width: 6),
            Expanded(child: _timeChip('정확한 시간', member.useExactTime && !member.timeUnknown, () {
              setState(() { member.useExactTime = true; member.timeUnknown = false; });
            })),
            const SizedBox(width: 6),
            Expanded(child: _timeChip('모름', member.timeUnknown, () {
              setState(() => member.timeUnknown = true);
            })),
          ],
        ),
        if (!member.timeUnknown && !member.useExactTime) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _siJinTeam.map((entry) {
              final selected = member.selectedSiJin == entry.$2;
              return GestureDetector(
                onTap: () => setState(() => member.selectedSiJin = entry.$2),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 40 - 28 - 12) / 3,
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF8A4FFF).withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? const Color(0xFF8A4FFF) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    entry.$1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? const Color(0xFF8A4FFF) : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (!member.timeUnknown && member.useExactTime) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: member.exactTime);
              if (picked != null) setState(() => member.exactTime = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Color(0xFF8A4FFF)),
                  const SizedBox(width: 8),
                  Text(member.exactTime.format(context), style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _timeChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF8A4FFF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF8A4FFF) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF4B5563),
          )),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (result != true) return;
    }

    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    try {
      await ticketProvider.consumeTicket('team_compatibility');
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
      final members = _members.map((m) {
        return <String, dynamic>{
          'name': m.name.isEmpty ? null : m.name,
          'birthDate': DateFormat('yyyy-MM-dd').format(m.birthDate),
          'birthTime': m.birthTimeValue,
          'gender': m.gender,
        };
      }).toList();

      final result = await ApiService().getTeamCompatibility(
        members: members,
        relationship: _relationship,
      );
      if (mounted) {
        setState(() => _result = result['consultation'] as String?);
        // 분석 완료 → 히스토리 다시 로드 + 히스토리 뷰로 전환
        await _loadHistory();
        if (mounted) setState(() => _showNewAnalysis = false);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _MemberData {
  String name = '';
  DateTime birthDate = DateTime(1990, 1, 1);
  String gender = 'male';
  String? selectedSiJin;
  TimeOfDay exactTime = const TimeOfDay(hour: 12, minute: 0);
  bool useExactTime = false;
  bool timeUnknown = true;

  String get birthTimeValue {
    if (timeUnknown) return 'unknown';
    if (useExactTime) {
      return '${exactTime.hour.toString().padLeft(2, '0')}:${exactTime.minute.toString().padLeft(2, '0')}';
    }
    return selectedSiJin ?? 'unknown';
  }
}
