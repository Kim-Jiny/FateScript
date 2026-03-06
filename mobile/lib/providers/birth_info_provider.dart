import 'package:flutter/foundation.dart';
import '../models/birth_info.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class BirthInfoProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();
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

  /// 로그인 후 서버와 사주 동기화
  Future<void> syncWithServer() async {
    try {
      if (_birthInfo != null) {
        // 로컬 사주가 있으면 서버에 저장
        await _api.saveUserSaju(_birthInfo!);
      } else {
        // 로컬 사주가 없으면 서버에서 가져오기
        final serverInfo = await _api.getUserSaju();
        if (serverInfo != null) {
          _birthInfo = serverInfo;
          await _storage.saveBirthInfo(serverInfo);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Saju sync failed: $e');
    }
  }

  Future<void> clear() async {
    _birthInfo = null;
    await _storage.clear();
    notifyListeners();
  }
}
