import 'package:flutter/foundation.dart';
import '../models/birth_info.dart';
import '../models/fortune_result.dart';
import '../models/daily_fortune.dart';
import '../models/name_analysis_result.dart';
import '../models/compatibility_result.dart';
import '../models/compatibility_history_item.dart';
import '../models/name_history_item.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class FortuneProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  FortuneResult? _fortuneResult;
  DailyFortune? _dailyFortune;
  NameAnalysisResult? _nameAnalysisResult;
  NameRecommendResult? _nameRecommendResult;
  CompatibilityResult? _compatibilityResult;
  List<CompatibilityHistoryItem> _compatibilityHistory = [];
  List<NameHistoryItem> _nameHistory = [];
  bool _isLoading = false;
  String? _error;

  FortuneResult? get fortuneResult => _fortuneResult;
  DailyFortune? get dailyFortune => _dailyFortune;
  NameAnalysisResult? get nameAnalysisResult => _nameAnalysisResult;
  NameRecommendResult? get nameRecommendResult => _nameRecommendResult;
  CompatibilityResult? get compatibilityResult => _compatibilityResult;
  List<CompatibilityHistoryItem> get compatibilityHistory => _compatibilityHistory;
  List<NameHistoryItem> get nameHistory => _nameHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSavedData() async {
    _fortuneResult = await _storage.loadFortuneResult();
    _dailyFortune = await _storage.loadDailyFortune();
    _compatibilityResult = await _storage.loadCompatibility();
    notifyListeners();
  }

  /// 하위 호환용 alias
  Future<void> loadSavedFortune() => loadSavedData();

  /// 서버에서 유저가 이전에 요청한 결과들을 불러와서 로컬 캐시에 저장
  /// 현재 사주 정보와 일치하는 결과만 복원
  Future<void> loadFromServer(BirthInfo? currentBirthInfo) async {
    if (currentBirthInfo == null) return;

    try {
      final results = await _api.getMyResults();
      final now = DateTime.now();

      for (final item in results) {
        final type = item['type'] as String;
        final result = item['result'] as Map<String, dynamic>;
        final params = item['params'] as Map<String, dynamic>?;

        // params의 사주 정보가 현재 사주와 일치하는지 확인
        if (params != null && !_matchesBirthInfo(params, currentBirthInfo)) {
          continue;
        }

        if (type == 'fortune') {
          final year = item['year'] as int?;
          if (year != null && year == now.year && _fortuneResult == null) {
            _fortuneResult = FortuneResult.fromJson(result);
            await _storage.saveFortuneResult(_fortuneResult!);
          }
        } else if (type == 'daily') {
          final dateStr = item['date'] as String?;
          final todayStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          if (dateStr == todayStr && _dailyFortune == null) {
            _dailyFortune = DailyFortune.fromJson(result);
            await _storage.saveDailyFortune(_dailyFortune!);
          }
        } else if (type == 'name_analyze') {
          if (_nameAnalysisResult == null) {
            _nameAnalysisResult = NameAnalysisResult.fromJson(result);
          }
        } else if (type == 'name_recommend') {
          if (_nameRecommendResult == null) {
            _nameRecommendResult = NameRecommendResult.fromJson(result);
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load results from server: $e');
    }
  }

  bool _matchesBirthInfo(Map<String, dynamic> params, BirthInfo info) {
    return params['birthDate'] == info.birthDate &&
        params['birthTime'] == (info.birthTime ?? 'unknown') &&
        params['gender'] == info.gender;
  }

  Future<void> clearSavedFortune() async {
    _fortuneResult = null;
    await _storage.clearFortuneResult();
    notifyListeners();
  }

  Future<void> clearAllSaved() async {
    _fortuneResult = null;
    _dailyFortune = null;
    _compatibilityResult = null;
    await _storage.clearFortuneResult();
    await _storage.clearDailyFortune();
    await _storage.clearCompatibility();
    notifyListeners();
  }

  Future<void> fetchFortune(BirthInfo info) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _fortuneResult = await _api.getFortune(info);
      await _storage.saveFortuneResult(_fortuneResult!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDailyFortune(BirthInfo info) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dailyFortune = await _api.getDailyFortune(info);
      await _storage.saveDailyFortune(_dailyFortune!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> analyzeName(BirthInfo info, String name,
      {bool isLoggedIn = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _nameAnalysisResult = null;
    notifyListeners();

    try {
      _nameAnalysisResult = await _api.analyzeName(info, name);

      // 히스토리에 추가
      if (isLoggedIn) {
        await loadNameHistory(fromServer: true);
      } else {
        final entry = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'mode': 'analyze',
          'name': name,
          'lastName': null,
          'birthDate': info.birthDate,
          'birthTime': info.birthTime,
          'gender': info.gender,
          'result': _nameAnalysisResult!.toJson(),
          'createdAt': DateTime.now().toIso8601String(),
        };
        await _storage.addNameHistoryEntry(entry);
        _nameHistory.insert(0, NameHistoryItem.fromJson(entry));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recommendNames(BirthInfo info, String lastName,
      {bool isLoggedIn = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _nameRecommendResult = null;
    notifyListeners();

    try {
      _nameRecommendResult = await _api.recommendNames(info, lastName);

      // 히스토리에 추가
      if (isLoggedIn) {
        await loadNameHistory(fromServer: true);
      } else {
        final entry = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'mode': 'recommend',
          'name': null,
          'lastName': lastName,
          'birthDate': info.birthDate,
          'birthTime': info.birthTime,
          'gender': info.gender,
          'result': _nameRecommendResult!.toJson(),
          'createdAt': DateTime.now().toIso8601String(),
        };
        await _storage.addNameHistoryEntry(entry);
        _nameHistory.insert(0, NameHistoryItem.fromJson(entry));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCompatibility(
      BirthInfo myInfo, BirthInfo partnerInfo, String relationship,
      {bool isLoggedIn = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _compatibilityResult = null;
    notifyListeners();

    try {
      _compatibilityResult =
          await _api.getCompatibility(myInfo, partnerInfo, relationship);
      await _storage.saveCompatibility(_compatibilityResult!);

      // 히스토리에 추가
      if (isLoggedIn) {
        // 서버에서 히스토리 다시 로드 (서버가 자동 저장함)
        await loadCompatibilityHistory(fromServer: true);
      } else {
        // 로컬 히스토리에 직접 추가
        final entry = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'myBirthDate': myInfo.birthDate,
          'myBirthTime': myInfo.birthTime,
          'myGender': myInfo.gender,
          'partnerBirthDate': partnerInfo.birthDate,
          'partnerBirthTime': partnerInfo.birthTime,
          'partnerGender': partnerInfo.gender,
          'relationship': relationship,
          'result': _compatibilityResult!.toJson(),
          'createdAt': DateTime.now().toIso8601String(),
        };
        await _storage.addCompatibilityHistoryEntry(entry);
        _compatibilityHistory.insert(
            0, CompatibilityHistoryItem.fromJson(entry));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 성명학 히스토리 ──

  Future<void> loadNameHistory({required bool fromServer}) async {
    try {
      if (fromServer) {
        final list = await _api.getNameHistory();
        _nameHistory =
            list.map((e) => NameHistoryItem.fromJson(e)).toList();
      } else {
        final list = await _storage.loadNameHistory();
        _nameHistory =
            list.map((e) => NameHistoryItem.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Load name history failed: $e');
      _nameHistory = [];
    }
    notifyListeners();
  }

  Future<void> deleteNameHistoryItem(int id, bool fromServer) async {
    try {
      if (fromServer) {
        await _api.deleteNameHistory(id);
      } else {
        await _storage.deleteNameHistoryEntry(id);
      }
      _nameHistory.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── 궁합 히스토리 ──

  Future<void> loadCompatibilityHistory({required bool fromServer}) async {
    try {
      if (fromServer) {
        final list = await _api.getCompatibilityHistory();
        _compatibilityHistory =
            list.map((e) => CompatibilityHistoryItem.fromJson(e)).toList();
      } else {
        final list = await _storage.loadCompatibilityHistory();
        _compatibilityHistory =
            list.map((e) => CompatibilityHistoryItem.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Load compatibility history failed: $e');
      _compatibilityHistory = [];
    }
    notifyListeners();
  }

  Future<void> deleteCompatibilityHistoryItem(
      int id, bool fromServer) async {
    try {
      if (fromServer) {
        await _api.deleteCompatibilityHistory(id);
      } else {
        await _storage.deleteCompatibilityHistoryEntry(id);
      }
      _compatibilityHistory.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
