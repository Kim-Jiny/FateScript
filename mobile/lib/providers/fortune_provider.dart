import 'package:flutter/foundation.dart';
import '../models/birth_info.dart';
import '../models/fortune_result.dart';
import '../models/daily_fortune.dart';
import '../models/diary_result.dart';
import '../models/compatibility_result.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class FortuneProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  FortuneResult? _fortuneResult;
  DailyFortune? _dailyFortune;
  DiaryResult? _diaryResult;
  CompatibilityResult? _compatibilityResult;
  List<DiaryResult> _diaryHistory = [];
  bool _isLoading = false;
  String? _error;

  FortuneResult? get fortuneResult => _fortuneResult;
  DailyFortune? get dailyFortune => _dailyFortune;
  DiaryResult? get diaryResult => _diaryResult;
  CompatibilityResult? get compatibilityResult => _compatibilityResult;
  List<DiaryResult> get diaryHistory => _diaryHistory;
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

  Future<void> loadDiaryHistory() async {
    _diaryHistory = await _storage.loadDiaryHistory();
    notifyListeners();
  }

  Future<void> consultDiary(BirthInfo info, String diaryText) async {
    _isLoading = true;
    _error = null;
    _diaryResult = null;
    notifyListeners();

    try {
      final consultation = await _api.consultDiary(info, diaryText);
      final now = DateTime.now();
      final entry = DiaryResult(
        id: now.millisecondsSinceEpoch,
        consultation: consultation,
        diaryText: diaryText,
        date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      );
      _diaryResult = entry;
      await _storage.saveDiaryEntry(entry);
      _diaryHistory = await _storage.loadDiaryHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDiaryEntry(int id) async {
    await _storage.deleteDiaryEntry(id);
    _diaryHistory = await _storage.loadDiaryHistory();
    notifyListeners();
  }

  Future<void> fetchCompatibility(
      BirthInfo myInfo, BirthInfo partnerInfo, String relationship) async {
    _isLoading = true;
    _error = null;
    _compatibilityResult = null;
    notifyListeners();

    try {
      _compatibilityResult =
          await _api.getCompatibility(myInfo, partnerInfo, relationship);
      await _storage.saveCompatibility(_compatibilityResult!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
