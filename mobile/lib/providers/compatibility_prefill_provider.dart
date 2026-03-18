import 'package:flutter/foundation.dart';

class CompatibilityPrefillProvider extends ChangeNotifier {
  String? _birthDate;
  String? _birthTime;
  String? _gender;

  String? get birthDate => _birthDate;
  String? get birthTime => _birthTime;
  String? get gender => _gender;

  bool get hasPrefill => _birthDate != null;

  void setPrefill({
    required String birthDate,
    required String birthTime,
    required String gender,
  }) {
    _birthDate = birthDate;
    _birthTime = birthTime;
    _gender = gender;
    notifyListeners();
  }

  void clear() {
    _birthDate = null;
    _birthTime = null;
    _gender = null;
    notifyListeners();
  }
}
