import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../widgets/loading_overlay.dart';
import 'input_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _controller = TextEditingController();
  bool _showHistory = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: const Text('오늘의 일기', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _toggleChip(
                            label: '상담하기',
                            selected: !_showHistory,
                            onTap: () => setState(() => _showHistory = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _toggleChip(
                            label: '히스토리',
                            selected: _showHistory,
                            onTap: () => setState(() => _showHistory = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _showHistory
                        ? _historyTab(fortuneProvider)
                        : _consultTab(birthProvider, fortuneProvider),
                  ),
                ],
              ),
            ),
          ),
          if (fortuneProvider.isLoading)
            const LoadingOverlay(message: '운명선생이 일기를 읽고 있습니다...'),
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
            color: selected ? const Color(0xFF8A4FFF) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _consultTab(BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘 있었던 일이나 감정을 적어보세요.\n운명선생이 사주 관점에서 상담해 드립니다.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '오늘 하루는 어땠나요?\n기쁜 일, 힘든 일, 고민거리...\n자유롭게 적어주세요.',
                hintStyle: TextStyle(color: Color(0xFFD1D5DB), height: 1.6),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 15, height: 1.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: fortuneProvider.isLoading ? null : () => _submit(birthProvider, fortuneProvider),
              icon: const Icon(Icons.psychology),
              label: const Text('운명선생에게 상담받기'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF8A4FFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (fortuneProvider.error != null) ...[
            const SizedBox(height: 12),
            Text(fortuneProvider.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          if (fortuneProvider.diaryResult != null) ...[
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
                      Icon(Icons.psychology, color: Color(0xFF8A4FFF), size: 20),
                      SizedBox(width: 8),
                      Text(
                        '운명선생의 상담',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF8A4FFF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MarkdownBody(
                    data: fortuneProvider.diaryResult!.consultation,
                    styleSheet: MarkdownStyleSheet(
                      h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                      p: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF374151)),
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

  Widget _historyTab(FortuneProvider fortuneProvider) {
    final history = fortuneProvider.diaryHistory;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text(
              '아직 상담 기록이 없습니다.',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            const Text(
              '일기를 작성하고 상담을 받아보세요.',
              style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return _historyCard(context, entry, fortuneProvider);
      },
    );
  }

  Widget _historyCard(BuildContext context, dynamic entry, FortuneProvider fortuneProvider) {
    return GestureDetector(
      onTap: () => _showDetailDialog(context, entry),
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
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFF8A4FFF)),
                const SizedBox(width: 6),
                Text(
                  entry.date,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8A4FFF), fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _confirmDelete(context, entry.id, fortuneProvider),
                  child: const Icon(Icons.delete_outline, size: 20, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              entry.diaryText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, dynamic entry) {
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
                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF8A4FFF)),
                        const SizedBox(width: 6),
                        Text(
                          entry.date,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF8A4FFF), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('내 일기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                    const SizedBox(height: 8),
                    Text(
                      entry.diaryText,
                      style: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Icon(Icons.psychology, color: Color(0xFF8A4FFF), size: 20),
                        SizedBox(width: 8),
                        Text(
                          '운명선생의 상담',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF8A4FFF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    MarkdownBody(
                      data: entry.consultation,
                      styleSheet: MarkdownStyleSheet(
                        h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                        p: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF374151)),
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

  void _confirmDelete(BuildContext context, int id, FortuneProvider fortuneProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('상담 기록 삭제'),
        content: const Text('이 상담 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              fortuneProvider.deleteDiaryEntry(id);
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _noBirthInfo(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_note_outlined, size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text('사주 정보를 먼저 입력해 주세요.', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InputScreen()),
              ),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8A4FFF)),
              child: const Text('사주 입력하기'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일기 내용을 입력해 주세요.')),
      );
      return;
    }
    fortuneProvider.consultDiary(birthProvider.birthInfo!, text);
  }
}
