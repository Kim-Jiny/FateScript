import 'name_analysis_result.dart';

class NameHistoryItem {
  final int id;
  final String mode; // 'analyze' | 'recommend'
  final String? name;
  final String? lastName;
  final String birthDate;
  final String? birthTime;
  final String gender;
  final Map<String, dynamic> result;
  final String createdAt;

  const NameHistoryItem({
    required this.id,
    required this.mode,
    this.name,
    this.lastName,
    required this.birthDate,
    this.birthTime,
    required this.gender,
    required this.result,
    required this.createdAt,
  });

  factory NameHistoryItem.fromJson(Map<String, dynamic> json) {
    return NameHistoryItem(
      id: json['id'] as int,
      mode: json['mode'] as String,
      name: json['name'] as String?,
      lastName: json['lastName'] as String?,
      birthDate: json['birthDate'] as String,
      birthTime: json['birthTime'] as String?,
      gender: json['gender'] as String,
      result: json['result'] as Map<String, dynamic>,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode,
        'name': name,
        'lastName': lastName,
        'birthDate': birthDate,
        'birthTime': birthTime,
        'gender': gender,
        'result': result,
        'createdAt': createdAt,
      };

  String get displayName {
    if (mode == 'analyze') return name ?? '';
    return '${lastName ?? ''} 추천';
  }

  String get modeLabel => mode == 'analyze' ? '이름 해석' : '이름 추천';

  int get overallScore {
    if (mode == 'analyze') {
      return result['overallScore'] as int? ?? 0;
    }
    // 추천 모드: 첫 번째 추천 이름의 점수
    final recs = result['recommendations'] as List?;
    if (recs != null && recs.isNotEmpty) {
      return (recs.first as Map<String, dynamic>)['score'] as int? ?? 0;
    }
    return 0;
  }

  NameAnalysisResult get analysisResult =>
      NameAnalysisResult.fromJson(result);

  NameRecommendResult get recommendResult =>
      NameRecommendResult.fromJson(result);
}
