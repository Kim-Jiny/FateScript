import 'dart:convert';

class SajuPillar {
  final String hangul;
  final String hanja;

  const SajuPillar({required this.hangul, required this.hanja});

  factory SajuPillar.fromJson(Map<String, dynamic> json) => SajuPillar(
        hangul: json['hangul'] as String,
        hanja: json['hanja'] as String,
      );

  Map<String, dynamic> toJson() => {'hangul': hangul, 'hanja': hanja};
}

class OhengInfo {
  final Map<String, int> distribution;
  final String dominantName;
  final String dominantEmoji;
  final String weakName;
  final String weakEmoji;
  final String summary;

  const OhengInfo({
    required this.distribution,
    required this.dominantName,
    required this.dominantEmoji,
    required this.weakName,
    required this.weakEmoji,
    required this.summary,
  });

  factory OhengInfo.fromJson(Map<String, dynamic> json) {
    final dist = (json['distribution'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    final dominant = json['dominant'] as Map<String, dynamic>;
    final weak = json['weak'] as Map<String, dynamic>;
    return OhengInfo(
      distribution: dist,
      dominantName: dominant['name'] as String,
      dominantEmoji: dominant['emoji'] as String,
      weakName: weak['name'] as String,
      weakEmoji: weak['emoji'] as String,
      summary: json['summary'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'distribution': distribution,
        'dominant': {'name': dominantName, 'emoji': dominantEmoji},
        'weak': {'name': weakName, 'emoji': weakEmoji},
        'summary': summary,
      };
}

class FortuneCategory {
  final String key;
  final String label;
  final String emoji;
  final String content;

  const FortuneCategory({
    required this.key,
    required this.label,
    required this.emoji,
    required this.content,
  });

  factory FortuneCategory.fromJson(Map<String, dynamic> json) =>
      FortuneCategory(
        key: json['key'] as String,
        label: json['label'] as String,
        emoji: json['emoji'] as String,
        content: json['content'] as String,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'emoji': emoji,
        'content': content,
      };
}

class FortuneResult {
  final SajuPillar yearPillar;
  final SajuPillar monthPillar;
  final SajuPillar dayPillar;
  final SajuPillar? hourPillar;
  final OhengInfo oheng;
  final String manseryeok;
  final String yearFortune;
  final String interpretation;
  final List<FortuneCategory> categories;

  const FortuneResult({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    this.hourPillar,
    required this.oheng,
    this.manseryeok = '',
    this.yearFortune = '',
    required this.interpretation,
    this.categories = const [],
  });

  factory FortuneResult.fromJson(Map<String, dynamic> json) {
    final saju = json['saju'] as Map<String, dynamic>;
    final rawCategories = json['categories'] as List<dynamic>?;

    var rawManseryeok = (json['manseryeok'] as String?) ?? '';
    var rawYearFortune = (json['yearFortune'] as String?) ?? '';
    var rawInterpretation = (json['interpretation'] as String?) ?? rawManseryeok;

    // ```json 코드펜스로 감싸진 AI 응답 정리
    final cleaned = _cleanJsonFence(rawManseryeok.isNotEmpty ? rawManseryeok : rawInterpretation);
    if (cleaned != null) {
      rawManseryeok = cleaned['manseryeok'] ?? rawManseryeok;
      rawInterpretation = cleaned['manseryeok'] ?? rawInterpretation;
      if (rawYearFortune.isEmpty && cleaned['yearFortune'] != null) {
        rawYearFortune = cleaned['yearFortune']!;
      }
    }

    return FortuneResult(
      yearPillar:
          SajuPillar.fromJson(saju['yearPillar'] as Map<String, dynamic>),
      monthPillar:
          SajuPillar.fromJson(saju['monthPillar'] as Map<String, dynamic>),
      dayPillar:
          SajuPillar.fromJson(saju['dayPillar'] as Map<String, dynamic>),
      hourPillar: saju['hourPillar'] != null
          ? SajuPillar.fromJson(saju['hourPillar'] as Map<String, dynamic>)
          : null,
      oheng: OhengInfo.fromJson(json['oheng'] as Map<String, dynamic>),
      manseryeok: rawManseryeok,
      yearFortune: rawYearFortune,
      interpretation: rawInterpretation,
      categories: rawCategories
              ?.map((e) =>
                  FortuneCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// ```json { "manseryeok": "..." } ``` 형태의 AI 응답에서 실제 내용 추출
  static Map<String, String>? _cleanJsonFence(String text) {
    final match = RegExp(r'^```(?:json)?\s*\n?([\s\S]*)').firstMatch(text);
    if (match == null) return null;

    var inner = match.group(1) ?? '';
    inner = inner.replaceAll(RegExp(r'\n?```\s*$'), '');

    // 정상 JSON 파싱 시도
    try {
      final parsed = Map<String, dynamic>.from(
        (const JsonDecoder().convert(inner)) as Map,
      );
      return {
        if (parsed['manseryeok'] is String) 'manseryeok': parsed['manseryeok'] as String,
        if (parsed['yearFortune'] is String) 'yearFortune': parsed['yearFortune'] as String,
      };
    } catch (_) {}

    // truncated JSON: regex로 "manseryeok": "..." 추출
    final result = <String, String>{};
    final mMatch = RegExp(r'"manseryeok"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(inner);
    if (mMatch != null) {
      try {
        result['manseryeok'] = const JsonDecoder().convert('"${mMatch.group(1)}"') as String;
      } catch (_) {
        result['manseryeok'] = mMatch.group(1) ?? '';
      }
    }
    final yMatch = RegExp(r'"yearFortune"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(inner);
    if (yMatch != null) {
      try {
        result['yearFortune'] = const JsonDecoder().convert('"${yMatch.group(1)}"') as String;
      } catch (_) {
        result['yearFortune'] = yMatch.group(1) ?? '';
      }
    }
    return result.isEmpty ? null : result;
  }

  Map<String, dynamic> toJson() => {
        'saju': {
          'yearPillar': yearPillar.toJson(),
          'monthPillar': monthPillar.toJson(),
          'dayPillar': dayPillar.toJson(),
          'hourPillar': hourPillar?.toJson(),
        },
        'oheng': oheng.toJson(),
        'manseryeok': manseryeok,
        'yearFortune': yearFortune,
        'interpretation': interpretation,
        'categories': categories.map((c) => c.toJson()).toList(),
      };
}
