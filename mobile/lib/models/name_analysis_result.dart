class NameCharacter {
  final String char;
  final String? hanja;
  final int strokes;
  final String oheng;
  final String yinYang;

  const NameCharacter({
    required this.char,
    this.hanja,
    required this.strokes,
    required this.oheng,
    required this.yinYang,
  });

  factory NameCharacter.fromJson(Map<String, dynamic> json) => NameCharacter(
        char: json['char'] as String,
        hanja: json['hanja'] as String?,
        strokes: json['strokes'] as int,
        oheng: json['oheng'] as String,
        yinYang: json['yinYang'] as String,
      );

  Map<String, dynamic> toJson() => {
        'char': char,
        'hanja': hanja,
        'strokes': strokes,
        'oheng': oheng,
        'yinYang': yinYang,
      };
}

class NameAnalysisResult {
  final List<NameCharacter> characters;
  final String ohengBalance;
  final String yinYangBalance;
  final String sajuCompatibility;
  final List<String> strengths;
  final List<String> cautions;
  final int overallScore;
  final String advice;

  const NameAnalysisResult({
    required this.characters,
    required this.ohengBalance,
    required this.yinYangBalance,
    required this.sajuCompatibility,
    required this.strengths,
    required this.cautions,
    required this.overallScore,
    required this.advice,
  });

  factory NameAnalysisResult.fromJson(Map<String, dynamic> json) {
    return NameAnalysisResult(
      characters: (json['characters'] as List?)
              ?.map((e) => NameCharacter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ohengBalance: json['ohengBalance'] as String? ?? '',
      yinYangBalance: json['yinYangBalance'] as String? ?? '',
      sajuCompatibility: json['sajuCompatibility'] as String? ?? '',
      strengths: (json['strengths'] as List?)?.map((e) => e as String).toList() ?? [],
      cautions: (json['cautions'] as List?)?.map((e) => e as String).toList() ?? [],
      overallScore: json['overallScore'] as int? ?? 0,
      advice: json['advice'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'characters': characters.map((e) => e.toJson()).toList(),
        'ohengBalance': ohengBalance,
        'yinYangBalance': yinYangBalance,
        'sajuCompatibility': sajuCompatibility,
        'strengths': strengths,
        'cautions': cautions,
        'overallScore': overallScore,
        'advice': advice,
      };
}

class NameRecommendation {
  final String name;
  final String hanja;
  final String meaning;
  final List<int> strokes;
  final String ohengAnalysis;
  final String sajuFit;
  final int score;

  const NameRecommendation({
    required this.name,
    required this.hanja,
    required this.meaning,
    required this.strokes,
    required this.ohengAnalysis,
    required this.sajuFit,
    required this.score,
  });

  factory NameRecommendation.fromJson(Map<String, dynamic> json) => NameRecommendation(
        name: json['name'] as String,
        hanja: json['hanja'] as String? ?? '',
        meaning: json['meaning'] as String? ?? '',
        strokes: (json['strokes'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
        ohengAnalysis: json['ohengAnalysis'] as String? ?? '',
        sajuFit: json['sajuFit'] as String? ?? '',
        score: json['score'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'hanja': hanja,
        'meaning': meaning,
        'strokes': strokes,
        'ohengAnalysis': ohengAnalysis,
        'sajuFit': sajuFit,
        'score': score,
      };
}

class NameRecommendResult {
  final List<NameRecommendation> recommendations;
  final String selectionCriteria;
  final String advice;

  const NameRecommendResult({
    required this.recommendations,
    required this.selectionCriteria,
    required this.advice,
  });

  factory NameRecommendResult.fromJson(Map<String, dynamic> json) {
    return NameRecommendResult(
      recommendations: (json['recommendations'] as List?)
              ?.map((e) => NameRecommendation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      selectionCriteria: json['selectionCriteria'] as String? ?? '',
      advice: json['advice'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'recommendations': recommendations.map((e) => e.toJson()).toList(),
        'selectionCriteria': selectionCriteria,
        'advice': advice,
      };
}
