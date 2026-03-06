import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/birth_info.dart';
import '../models/fortune_result.dart';
import '../models/daily_fortune.dart';
import '../models/compatibility_result.dart';

class ApiService {
  // 실제 디바이스: Mac의 로컬 IP 사용
  // 에뮬레이터: Android 10.0.2.2 / iOS localhost
  static const _baseUrl = 'http://172.30.1.80:3000';

  static const _timeout = Duration(seconds: 30);

  Future<FortuneResult> getFortune(BirthInfo info) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/fortune'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(info.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('사주 해석 요청에 실패했습니다 (${response.statusCode})');
    }

    return FortuneResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<DailyFortune> getDailyFortune(BirthInfo info) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/daily'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(info.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('오늘의 운세 요청에 실패했습니다 (${response.statusCode})');
    }

    return DailyFortune.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<String> consultDiary(BirthInfo info, String diaryText) async {
    final body = {
      ...info.toJson(),
      'diaryText': diaryText,
    };

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/diary'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('일기 상담 요청에 실패했습니다 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['consultation'] as String;
  }

  Future<CompatibilityResult> getCompatibility(
      BirthInfo myInfo, BirthInfo partnerInfo, String relationship) async {
    final body = {
      'myBirthDate': myInfo.birthDate,
      'myBirthTime': myInfo.birthTime ?? 'unknown',
      'myGender': myInfo.gender,
      'partnerBirthDate': partnerInfo.birthDate,
      'partnerBirthTime': partnerInfo.birthTime ?? 'unknown',
      'partnerGender': partnerInfo.gender,
      'relationship': relationship,
    };

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/compatibility'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('궁합 분석 요청에 실패했습니다 (${response.statusCode})');
    }

    return CompatibilityResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }
}
