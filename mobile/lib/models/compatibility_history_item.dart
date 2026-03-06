class CompatibilityHistoryItem {
  final int id;
  final String myBirthDate;
  final String? myBirthTime;
  final String myGender;
  final String partnerBirthDate;
  final String? partnerBirthTime;
  final String partnerGender;
  final String relationship;
  final Map<String, dynamic> result;
  final String createdAt;

  const CompatibilityHistoryItem({
    required this.id,
    required this.myBirthDate,
    this.myBirthTime,
    required this.myGender,
    required this.partnerBirthDate,
    this.partnerBirthTime,
    required this.partnerGender,
    required this.relationship,
    required this.result,
    required this.createdAt,
  });

  factory CompatibilityHistoryItem.fromJson(Map<String, dynamic> json) {
    return CompatibilityHistoryItem(
      id: json['id'] as int,
      myBirthDate: json['myBirthDate'] as String,
      myBirthTime: json['myBirthTime'] as String?,
      myGender: json['myGender'] as String,
      partnerBirthDate: json['partnerBirthDate'] as String,
      partnerBirthTime: json['partnerBirthTime'] as String?,
      partnerGender: json['partnerGender'] as String,
      relationship: json['relationship'] as String,
      result: json['result'] as Map<String, dynamic>,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'myBirthDate': myBirthDate,
        'myBirthTime': myBirthTime,
        'myGender': myGender,
        'partnerBirthDate': partnerBirthDate,
        'partnerBirthTime': partnerBirthTime,
        'partnerGender': partnerGender,
        'relationship': relationship,
        'result': result,
        'createdAt': createdAt,
      };

  String get consultation => result['consultation'] as String? ?? '';

  String get relationshipLabel {
    const labels = {
      'lover': '연인',
      'spouse': '배우자',
      'friend': '친구',
      'colleague': '동료',
      'family': '가족',
    };
    return labels[relationship] ?? relationship;
  }
}
