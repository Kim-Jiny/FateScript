class DailyFortune {
  final String date;
  final String iljinHangul;
  final String iljinHanja;
  final String reading;

  const DailyFortune({
    required this.date,
    required this.iljinHangul,
    required this.iljinHanja,
    required this.reading,
  });

  factory DailyFortune.fromJson(Map<String, dynamic> json) {
    final iljin = json['iljin'] as Map<String, dynamic>;
    return DailyFortune(
      date: json['date'] as String,
      iljinHangul: iljin['hangul'] as String,
      iljinHanja: iljin['hanja'] as String,
      reading: json['reading'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'iljin': {'hangul': iljinHangul, 'hanja': iljinHanja},
        'reading': reading,
      };
}
