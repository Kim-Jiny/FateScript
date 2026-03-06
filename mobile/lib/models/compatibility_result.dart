class CompatibilityResult {
  final String consultation;

  const CompatibilityResult({required this.consultation});

  factory CompatibilityResult.fromJson(Map<String, dynamic> json) =>
      CompatibilityResult(consultation: json['consultation'] as String);

  Map<String, dynamic> toJson() => {'consultation': consultation};
}
