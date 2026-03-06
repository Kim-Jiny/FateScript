import 'package:flutter/material.dart';
import '../data/hanja_dict.dart';

// 같은 한자의 다른 음가 (두음법칙, 성씨 발음 등)
const Map<String, List<String>> _variantMap = {
  '김': ['금'],
  '금': ['김'],
  '이': ['리'],
  '리': ['이'],
  '임': ['림'],
  '림': ['임'],
  '나': ['라'],
  '라': ['나'],
  '노': ['로'],
  '로': ['노'],
  '녕': ['령'],
  '령': ['녕'],
  '년': ['연'],
  '연': ['년'],
  '뇌': ['뢰'],
  '뢰': ['뇌'],
  '누': ['루'],
  '루': ['누'],
  '류': ['유'],
  '유': ['류'],
  '렬': ['열'],
  '열': ['렬'],
  '량': ['양'],
  '양': ['량'],
  '란': ['난'],
  '난': ['란'],
  '래': ['내'],
  '내': ['래'],
  '여': ['려'],
  '려': ['여'],
  '염': ['렴'],
  '렴': ['염'],
};

/// 한글 글자에 해당하는 한자 후보를 검색 (음가 변환 포함)
List<HanjaEntry> _findCandidates(String char) {
  final direct = hanjaDict[char];
  final variants = _variantMap[char];

  if (variants == null) return direct ?? [];

  // 중복 제거를 위해 한자 문자 기준으로 합침
  final seen = <String>{};
  final result = <HanjaEntry>[];

  for (final entry in direct ?? <HanjaEntry>[]) {
    if (seen.add(entry.hanja)) result.add(entry);
  }
  for (final v in variants) {
    for (final entry in hanjaDict[v] ?? <HanjaEntry>[]) {
      if (seen.add(entry.hanja)) result.add(entry);
    }
  }

  return result;
}

class HanjaSelector extends StatelessWidget {
  final String name;
  final Map<int, HanjaEntry> selectedHanja;
  final ValueChanged<Map<int, HanjaEntry>> onChanged;

  const HanjaSelector({
    super.key,
    required this.name,
    required this.selectedHanja,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty) return const SizedBox.shrink();

    final chars = name.characters.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '한자 선택',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '각 글자에 해당하는 한자를 선택하세요. (선택사항)',
          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 12),
        ...List.generate(chars.length, (i) {
          final char = chars[i];
          final candidates = _findCandidates(char);
          final selected = selectedHanja[i];

          return _charRow(context, i, char, candidates, selected);
        }),
      ],
    );
  }

  Widget _charRow(BuildContext context, int index, String char,
      List<HanjaEntry> candidates, HanjaEntry? selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF8A4FFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    char,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A4FFF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (selected != null) ...[
                Text(
                  selected.hanja,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  '${selected.meaning} (${selected.strokes}획)',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    final updated = Map<int, HanjaEntry>.from(selectedHanja);
                    updated.remove(index);
                    onChanged(updated);
                  },
                  child: const Icon(Icons.close,
                      size: 18, color: Color(0xFF9CA3AF)),
                ),
              ] else ...[
                Text(
                  candidates.isNotEmpty ? '한자를 선택하세요' : '한자 정보 없음',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ],
            ],
          ),
          if (candidates.isNotEmpty && selected == null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: candidates.map((entry) {
                return GestureDetector(
                  onTap: () {
                    final updated = Map<int, HanjaEntry>.from(selectedHanja);
                    updated[index] = entry;
                    onChanged(updated);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.hanja,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.meaning,
                          style: const TextStyle(
                              fontSize: 9, color: Color(0xFF6B7280)),
                        ),
                        Text(
                          '${entry.strokes}획',
                          style: const TextStyle(
                              fontSize: 9, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
