class DiaryResult {
  final int id;
  final String consultation;
  final String diaryText;
  final String date;

  const DiaryResult({
    required this.id,
    required this.consultation,
    required this.diaryText,
    required this.date,
  });

  factory DiaryResult.fromJson(Map<String, dynamic> json) => DiaryResult(
        id: json['id'] as int,
        consultation: json['consultation'] as String,
        diaryText: json['diaryText'] as String,
        date: json['date'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'consultation': consultation,
        'diaryText': diaryText,
        'date': date,
      };
}
