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
    debugPrint('[Sync] syncWithServer called, birthInfo=${_birthInfo != null ? '${_birthInfo!.birthDate}/${_birthInfo!.gender}' : 'NULL'}');
    try {
      if (_birthInfo != null) {
        // 로컬 사주가 있으면 서버에 저장
        debugPrint('[Sync] Saving local saju to server...');
        await _api.saveUserSaju(_birthInfo!);
        debugPrint('[Sync] Save success');
      } else {
        // 로컬 사주가 없으면 서버에서 가져오기
        debugPrint('[Sync] No local saju, fetching from server...');
        final serverInfo = await _api.getUserSaju();
        debugPrint('[Sync] Server returned: ${serverInfo?.birthDate}');
        if (serverInfo != null) {
          _birthInfo = serverInfo;
          await _storage.saveBirthInfo(serverInfo);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[Sync] Saju sync FAILED: $e');
    }
  }

  Future<void> clear() async {
    _birthInfo = null;
    await _storage.clear();
    notifyListeners();
  }
}
