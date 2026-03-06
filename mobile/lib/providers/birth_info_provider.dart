import 'package:flutter/foundation.dart';
import '../models/birth_info.dart';
import '../services/storage_service.dart';

class BirthInfoProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  BirthInfo? _birthInfo;
  VoidCallback? onBirthInfoChanged;

  BirthInfo? get birthInfo => _birthInfo;
  bool get hasBirthInfo => _birthInfo != null;

  Future<void> load() async {
    _birthInfo = await _storage.loadBirthInfo();
    notifyListeners();
  }

  Future<void> save(BirthInfo info) async {
    final changed = _birthInfo == null ||
        _birthInfo!.birthDate != info.birthDate ||
        _birthInfo!.birthTime != info.birthTime ||
        _birthInfo!.gender != info.gender;
    _birthInfo = info;
    await _storage.saveBirthInfo(info);
    if (changed) onBirthInfoChanged?.call();
    notifyListeners();
  }

  Future<void> clear() async {
    _birthInfo = null;
    await _storage.clear();
    notifyListeners();
  }
}
