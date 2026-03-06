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
  final String interpretation;
  final List<FortuneCategory> categories;

  const FortuneResult({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    this.hourPillar,
    required this.oheng,
    required this.interpretation,
    this.categories = const [],
  });

  factory FortuneResult.fromJson(Map<String, dynamic> json) {
    final saju = json['saju'] as Map<String, dynamic>;
    final rawCategories = json['categories'] as List<dynamic>?;
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
      interpretation: json['interpretation'] as String,
      categories: rawCategories
              ?.map((e) =>
                  FortuneCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'saju': {
          'yearPillar': yearPillar.toJson(),
          'monthPillar': monthPillar.toJson(),
          'dayPillar': dayPillar.toJson(),
          'hourPillar': hourPillar?.toJson(),
        },
        'oheng': oheng.toJson(),
        'interpretation': interpretation,
        'categories': categories.map((c) => c.toJson()).toList(),
      };
}
