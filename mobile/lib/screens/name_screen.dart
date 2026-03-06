import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/name_analysis_result.dart';
import '../providers/birth_info_provider.dart';
import '../providers/fortune_provider.dart';
import '../widgets/loading_overlay.dart';
import 'input_screen.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  bool _isRecommendMode = false;
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
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

  Widget _analyzeTab(
      BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이름을 입력하면 사주와의 궁합을 분석합니다.\n한자 획수, 오행, 음양을 종합적으로 평가합니다.',
            style: TextStyle(
                fontSize: 12, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '이름을 입력하세요 (예: 홍길동)',
                hintStyle: TextStyle(color: Color(0xFFD1D5DB)),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
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
          // Character breakdown
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
          const SizedBox(height: 16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  Icon(Icons.auto_awesome,
                      color: Color(0xFF8A4FFF), size: 20),
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
              ...result.recommendations
                  .map((r) => _recommendationCard(r)),
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
        ),
      ],
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

  Widget _noBirthInfo(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.text_fields,
                size: 64, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            const Text('사주 정보를 먼저 입력해 주세요.',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
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

  void _submitAnalyze(
      BirthInfoProvider birthProvider, FortuneProvider fortuneProvider) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해 주세요.')),
      );
      return;
    }
    fortuneProvider.analyzeName(birthProvider.birthInfo!, name);
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
    fortuneProvider.recommendNames(birthProvider.birthInfo!, lastName);
  }
}
