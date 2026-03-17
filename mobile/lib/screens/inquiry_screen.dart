import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _inquiries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _inquiries = await _api.getInquiries();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6EFE5),
      appBar: AppBar(
        title: const Text('문의하기'),
        backgroundColor: const Color(0xFFF6EFE5),
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8A4FFF)))
          : _inquiries.isEmpty
              ? const Center(
                  child: Text('문의 내역이 없습니다.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF8A4FFF),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _inquiries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _InquiryCard(
                      inquiry: _inquiries[i],
                      onTap: () => _showDetail(_inquiries[i]),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8A4FFF),
        onPressed: () => _showCreateSheet(),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateInquirySheet(
        onCreated: () {
          _load();
        },
      ),
    );
  }

  void _showDetail(Map<String, dynamic> inquiry) async {
    // 읽음 처리
    if (inquiry['status'] == 'replied' && inquiry['is_read'] == false) {
      try {
        await _api.markInquiryRead(inquiry['id'] as int);
      } catch (_) {}
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InquiryDetailSheet(inquiry: inquiry),
    ).then((_) => _load());
  }
}

class _InquiryCard extends StatelessWidget {
  final Map<String, dynamic> inquiry;
  final VoidCallback onTap;

  const _InquiryCard({required this.inquiry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = inquiry['status'] as String? ?? 'pending';
    final isReplied = status == 'replied';
    final isRead = inquiry['is_read'] == true;
    final createdAt = inquiry['created_at'] as String? ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isReplied && !isRead
                ? const Color(0xFF8A4FFF).withValues(alpha: 0.3)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReplied
                        ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isReplied ? '답변완료' : '대기중',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isReplied
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                if (isReplied && !isRead) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8A4FFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatCategory(inquiry['category'] as String? ?? ''),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A4FFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              inquiry['title'] as String? ?? '',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(createdAt),
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCategory(String cat) {
    switch (cat) {
      case 'bug':
        return '버그 신고';
      case 'suggestion':
        return '건의사항';
      case 'account':
        return '계정 문제';
      default:
        return '기타';
    }
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }
}

// ── 문의 작성 시트 ──

class _CreateInquirySheet extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateInquirySheet({required this.onCreated});

  @override
  State<_CreateInquirySheet> createState() => _CreateInquirySheetState();
}

class _CreateInquirySheetState extends State<_CreateInquirySheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _category = 'bug';
  bool _submitting = false;

  static const _categories = [
    ('bug', '버그 신고'),
    ('suggestion', '건의사항'),
    ('account', '계정 문제'),
    ('other', '기타'),
  ];

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService().createInquiry(
        category: _category,
        title: title,
        content: content,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('문의가 등록되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6EFE5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('새 문의 작성',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              // 카테고리
              const Text('카테고리',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((c) {
                  final selected = _category == c.$1;
                  return ChoiceChip(
                    label: Text(c.$2),
                    selected: selected,
                    selectedColor: const Color(0xFF8A4FFF).withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: selected
                          ? const Color(0xFF8A4FFF)
                          : const Color(0xFF6B7280),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF8A4FFF)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    onSelected: (_) => setState(() => _category = c.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 제목
              const Text('제목',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: '문의 제목을 입력하세요',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),

              // 내용
              const Text('내용',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              TextField(
                controller: _contentCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '문의 내용을 자세히 입력하세요',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 24),

              // 등록 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF8A4FFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('문의 등록',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 문의 상세 시트 ──

class _InquiryDetailSheet extends StatelessWidget {
  final Map<String, dynamic> inquiry;
  const _InquiryDetailSheet({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final status = inquiry['status'] as String? ?? 'pending';
    final isReplied = status == 'replied';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6EFE5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 상태 + 카테고리
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReplied
                        ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isReplied ? '답변완료' : '대기중',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isReplied
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatCategory(inquiry['category'] as String? ?? ''),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A4FFF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 제목
            Text(
              inquiry['title'] as String? ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(inquiry['created_at'] as String? ?? ''),
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 20),

            // 내용
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                inquiry['content'] as String? ?? '',
                style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF374151)),
              ),
            ),

            // 답변
            if (isReplied) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.support_agent, size: 18, color: Color(0xFF8A4FFF)),
                  const SizedBox(width: 6),
                  const Text('관리자 답변',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A4FFF))),
                  const Spacer(),
                  Text(
                    _formatDate(inquiry['replied_at'] as String? ?? ''),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8A4FFF).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8A4FFF).withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  inquiry['reply'] as String? ?? '',
                  style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF374151)),
                ),
              ),
            ],

            if (!isReplied) ...[
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '답변을 준비중입니다. 잠시만 기다려주세요.',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCategory(String cat) {
    switch (cat) {
      case 'bug':
        return '버그 신고';
      case 'suggestion':
        return '건의사항';
      case 'account':
        return '계정 문제';
      default:
        return '기타';
    }
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
