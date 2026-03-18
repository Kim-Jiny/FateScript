import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/birth_info.dart';
import '../models/compatibility_result.dart';
import '../models/daily_fortune.dart';
import '../models/fortune_result.dart';

class StorageService {
  static const _keyBirthDate = 'birth_date';
  static const _keyBirthTime = 'birth_time';
  static const _keyGender = 'gender';
  static const _keyFortuneResult = 'fortune_result';
  static const _keyFortuneSavedYear = 'fortune_saved_year';
  static const _keyDailyFortune = 'daily_fortune';
  static const _keyDailyFortuneSavedDate = 'daily_fortune_saved_date';
  static const _keyCompatibility = 'compatibility_result';
  static const _keyCompatibilitySavedYear = 'compatibility_saved_year';
  static const _keyCompatibilityHistory = 'compatibility_history';

  Future<void> saveBirthInfo(BirthInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBirthDate, info.birthDate);
    await prefs.setString(_keyBirthTime, info.birthTime ?? 'unknown');
    await prefs.setString(_keyGender, info.gender);
  }

  Future<BirthInfo?> loadBirthInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final birthDate = prefs.getString(_keyBirthDate);
    final gender = prefs.getString(_keyGender);
    if (birthDate == null || gender == null) return null;

    final birthTime = prefs.getString(_keyBirthTime);
    return BirthInfo(
      birthDate: birthDate,
      birthTime: birthTime,
      gender: gender,
    );
  }

  // ── 내 사주 (연도 단위 만료) ──

  Future<void> saveFortuneResult(FortuneResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFortuneResult, jsonEncode(result.toJson()));
    await prefs.setInt(_keyFortuneSavedYear, DateTime.now().year);
  }

  Future<FortuneResult?> loadFortuneResult() async {
    final prefs = await SharedPreferences.getInstance();
    final savedYear = prefs.getInt(_keyFortuneSavedYear);
    if (savedYear != null && savedYear != DateTime.now().year) {
      await clearFortuneResult();
      return null;
    }
    final json = prefs.getString(_keyFortuneResult);
    if (json == null) return null;
    try {
      return FortuneResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      await clearFortuneResult();
      return null;
    }
  }

  Future<void> clearFortuneResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFortuneResult);
    await prefs.remove(_keyFortuneSavedYear);
  }

  // ── 오늘의 운세 (날짜 단위 만료) ──

  Future<void> saveDailyFortune(DailyFortune result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDailyFortune, jsonEncode(result.toJson()));
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await prefs.setString(_keyDailyFortuneSavedDate, dateStr);
  }

  Future<DailyFortune?> loadDailyFortune() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_keyDailyFortuneSavedDate);
    if (savedDate != null) {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      if (savedDate != todayStr) {
        await clearDailyFortune();
        return null;
      }
    }
    final json = prefs.getString(_keyDailyFortune);
    if (json == null) return null;
    try {
      return DailyFortune.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      await clearDailyFortune();
      return null;
    }
  }

  Future<void> clearDailyFortune() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDailyFortune);
    await prefs.remove(_keyDailyFortuneSavedDate);
  }

  // ── 궁합 (연도 단위 만료) ──

  Future<void> saveCompatibility(CompatibilityResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCompatibility, jsonEncode(result.toJson()));
    await prefs.setInt(_keyCompatibilitySavedYear, DateTime.now().year);
  }

  Future<CompatibilityResult?> loadCompatibility() async {
    final prefs = await SharedPreferences.getInstance();
    final savedYear = prefs.getInt(_keyCompatibilitySavedYear);
    if (savedYear != null && savedYear != DateTime.now().year) {
      await clearCompatibility();
      return null;
    }
    final json = prefs.getString(_keyCompatibility);
    if (json == null) return null;
    try {
      return CompatibilityResult.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      await clearCompatibility();
      return null;
    }
  }

  Future<void> clearCompatibility() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCompatibility);
    await prefs.remove(_keyCompatibilitySavedYear);
  }

  // ── 궁합 히스토리 (로컬) ──

  Future<void> saveCompatibilityHistory(
      List<Map<String, dynamic>> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCompatibilityHistory, jsonEncode(history));
  }

  Future<List<Map<String, dynamic>>> loadCompatibilityHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyCompatibilityHistory);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> addCompatibilityHistoryEntry(
      Map<String, dynamic> entry) async {
    final history = await loadCompatibilityHistory();
    history.insert(0, entry);
    await saveCompatibilityHistory(history);
  }

  Future<void> deleteCompatibilityHistoryEntry(int id) async {
    final history = await loadCompatibilityHistory();
    history.removeWhere((e) => e['id'] == id);
    await saveCompatibilityHistory(history);
  }

  // ── 추천인 코드 (딥링크 보관) ──

  Future<void> savePendingReferralCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_referral_code', code);
  }

  Future<String?> loadPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pending_referral_code');
  }

  Future<void> clearPendingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_referral_code');
  }

  Future<bool> hasPromptedReferral() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('referral_prompted') ?? false;
  }

  Future<void> setReferralPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('referral_prompted', true);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBirthDate);
    await prefs.remove(_keyBirthTime);
    await prefs.remove(_keyGender);
    await clearFortuneResult();
    await clearDailyFortune();
    await clearCompatibility();
  }
}
