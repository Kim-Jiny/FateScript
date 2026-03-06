import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/birth_info.dart';
import '../models/fortune_result.dart';
import '../models/daily_fortune.dart';
import '../models/name_analysis_result.dart';
import '../models/compatibility_result.dart';

class ApiService {
  static const _baseUrl = 'https://fate.jiny.shop';

  static const _timeout = Duration(seconds: 30);

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_authToken != null) {
      h['Authorization'] = 'Bearer $_authToken';
    }
    return h;
  }

  Future<FortuneResult> getFortune(BirthInfo info) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/fortune'),
          headers: _headers,
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
          headers: _headers,
          body: jsonEncode(info.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('오늘의 운세 요청에 실패했습니다 (${response.statusCode})');
    }

    return DailyFortune.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<NameAnalysisResult> analyzeName(BirthInfo info, String name) async {
    final body = {
      'mode': 'analyze',
      'name': name,
      'birthDate': info.birthDate,
      'birthTime': info.birthTime ?? 'unknown',
      'gender': info.gender,
    };

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/name-analysis'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('이름 분석 요청에 실패했습니다 (${response.statusCode})');
    }

    return NameAnalysisResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<NameRecommendResult> recommendNames(
      BirthInfo info, String lastName) async {
    final body = {
      'mode': 'recommend',
      'lastName': lastName,
      'birthDate': info.birthDate,
      'birthTime': info.birthTime ?? 'unknown',
      'gender': info.gender,
    };

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/name-analysis'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('이름 추천 요청에 실패했습니다 (${response.statusCode})');
    }

    return NameRecommendResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
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
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('궁합 분석 요청에 실패했습니다 (${response.statusCode})');
    }

    return CompatibilityResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ── Auth API ──

  Future<void> saveUserSaju(BirthInfo info) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/user/saju'),
          headers: _headers,
          body: jsonEncode(info.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('사주 저장에 실패했습니다 (${response.statusCode})');
    }
  }

  Future<BirthInfo?> getUserSaju() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/user/saju'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('사주 조회에 실패했습니다 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['birthDate'] == null) return null;
    return BirthInfo(
      birthDate: json['birthDate'] as String,
      birthTime: json['birthTime'] as String?,
      gender: json['gender'] as String,
    );
  }

  // ── Compatibility History API ──

  Future<List<Map<String, dynamic>>> getCompatibilityHistory() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/compatibility/history'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('궁합 히스토리 조회에 실패했습니다 (${response.statusCode})');
    }

    final list = jsonDecode(response.body) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> deleteCompatibilityHistory(int id) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/api/compatibility/history/$id'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('궁합 히스토리 삭제에 실패했습니다 (${response.statusCode})');
    }
  }
}
