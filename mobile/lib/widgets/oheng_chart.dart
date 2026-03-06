import 'package:flutter/material.dart';
import '../models/fortune_result.dart';

class OhengChart extends StatelessWidget {
  final OhengInfo oheng;

  const OhengChart({super.key, required this.oheng});

  static const _ohengColors = {
    '목': Color(0xFF22C55E),
    '화': Color(0xFFEF4444),
    '토': Color(0xFFF59E0B),
    '금': Color(0xFF9CA3AF),
    '수': Color(0xFF3B82F6),
  };

  static const _ohengLabels = {
    '목': 'Wood',
    '화': 'Fire',
    '토': 'Earth',
    '금': 'Metal',
    '수': 'Water',
  };

  @override
  Widget build(BuildContext context) {
    final total = oheng.distribution.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오행 분포',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...oheng.distribution.entries.map((e) {
            final ratio = e.value / total;
            final color = _ohengColors[e.key] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${e.key} ${_ohengLabels[e.key] ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: const Color(0xFFF3F4F6),
                        color: color,
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${e.value}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
