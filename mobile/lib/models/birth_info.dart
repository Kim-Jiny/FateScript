class BirthInfo {
  final String birthDate; // yyyy-MM-dd
  final String? birthTime; // HH:mm or 'unknown'
  final String gender; // 'male' or 'female'
  final String? referralCode; // 추천인 코드 (가입 시에만 사용)

  const BirthInfo({
    required this.birthDate,
    this.birthTime,
    required this.gender,
    this.referralCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'birthDate': birthDate,
      'birthTime': birthTime ?? 'unknown',
      'gender': gender,
    };
    if (referralCode != null && referralCode!.isNotEmpty) {
      map['referralCode'] = referralCode;
    }
    return map;
  }

  factory BirthInfo.fromJson(Map<String, dynamic> json) => BirthInfo(
        birthDate: json['birthDate'] as String,
        birthTime: json['birthTime'] as String?,
        gender: json['gender'] as String,
      );

  bool get hasTime => birthTime != null && birthTime != 'unknown';
}
