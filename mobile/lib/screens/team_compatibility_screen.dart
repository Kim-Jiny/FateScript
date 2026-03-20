import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../services/api_service.dart';
import '../widgets/loading_overlay.dart';
import 'login_screen.dart';

class TeamCompatibilityView extends StatefulWidget {
  const TeamCompatibilityView({super.key});

  @override
  State<TeamCompatibilityView> createState() => _TeamCompatibilityViewState();
}

class _TeamCompatibilityViewState extends State<TeamCompatibilityView> {
  final List<_MemberData> _members = [
    _MemberData(),
    _MemberData(),
    _MemberData(),
  ];
  String _relationship = 'team';
  bool _isLoading = false;
  String? _error;
  String? _result;

  static const _relationships = [
    ('팀/프로젝트', 'team'),
    ('친구 모임', 'friends'),
    ('가족', 'family'),
    ('비즈니스', 'business'),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  label: const Text('팀 궁합 분석 (3티켓)'),
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
              Text('멤버 ${index + 1}',
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
        ],
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
            content: const Text('티켓이 부족합니다. (필요: 3장)\n마이페이지에서 티켓을 구매해 주세요.'),
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
          'birthTime': 'unknown',
          'gender': m.gender,
        };
      }).toList();

      final result = await ApiService().getTeamCompatibility(
        members: members,
        relationship: _relationship,
      );
      if (mounted) setState(() => _result = result['consultation'] as String?);
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
}
