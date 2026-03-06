import 'package:flutter/material.dart';
import '../models/fortune_result.dart';

// 천간 → 오행
const _stemElement = {
  '갑': '목', '을': '목',
  '병': '화', '정': '화',
  '무': '토', '기': '토',
  '경': '금', '신': '금',
  '임': '수', '계': '수',
};

// 지지 → 오행
const _branchElement = {
  '인': '목', '묘': '목',
  '사': '화', '오': '화',
  '진': '토', '술': '토', '축': '토', '미': '토',
  '신': '금', '유': '금',
  '해': '수', '자': '수',
};

const _ohengColor = {
  '목': Color(0xFF22C55E),
  '화': Color(0xFFEF4444),
  '토': Color(0xFFF59E0B),
  '금': Color(0xFF9CA3AF),
  '수': Color(0xFF3B82F6),
};

class PillarCard extends StatelessWidget {
  final String label;
  final SajuPillar pillar;
  final OhengInfo? oheng;

  const PillarCard({
    super.key,
    required this.label,
    required this.pillar,
    this.oheng,
  });

  double _intensity(String? element) {
    if (oheng == null || element == null) return 0.08;
    final dist = oheng!.distribution;
    final total = dist.values.fold(0, (a, b) => a + b);
    if (total == 0) return 0.08;
    final count = dist[element] ?? 0;
    return 0.04 + (count / total) * 0.45;
  }

  @override
  Widget build(BuildContext context) {
    final stem = pillar.hangul.characters.first;
    final branch = pillar.hangul.characters.last;
    final stemHanja = pillar.hanja.characters.first;
    final branchHanja = pillar.hanja.characters.last;

    final stemEl = _stemElement[stem];
    final branchEl = _branchElement[branch];
    final stemColor = _ohengColor[stemEl] ?? const Color(0xFF9CA3AF);
    final branchColor = _ohengColor[branchEl] ?? const Color(0xFF9CA3AF);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 16, bottom: 6, left: 12, right: 12),
            color: stemColor.withValues(alpha: _intensity(stemEl)),
            child: Column(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A4FFF),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  stemHanja,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: stemColor.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  stem,
                  style: TextStyle(fontSize: 13, color: stemColor.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 6, bottom: 16, left: 12, right: 12),
            color: branchColor.withValues(alpha: _intensity(branchEl)),
            child: Column(
              children: [
                Text(
                  branchHanja,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: branchColor.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  branch,
                  style: TextStyle(fontSize: 13, color: branchColor.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
