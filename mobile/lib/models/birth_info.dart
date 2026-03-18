class BirthInfo {
  final String birthDate; // yyyy-MM-dd
  final String? birthTime; // HH:mm or 'unknown'
  final String gender; // 'male' or 'female'

  const BirthInfo({
    required this.birthDate,
    this.birthTime,
    required this.gender,
  });

  Map<String, dynamic> toJson() => {
        'birthDate': birthDate,
        'birthTime': birthTime ?? 'unknown',
        'gender': gender,
      };

  factory BirthInfo.fromJson(Map<String, dynamic> json) => BirthInfo(
        birthDate: json['birthDate'] as String,
        birthTime: json['birthTime'] as String?,
        gender: json['gender'] as String,
      );

  bool get hasTime => birthTime != null && birthTime != 'unknown';
}
