import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/birth_info.dart';
import '../models/fortune_result.dart';
import '../models/daily_fortune.dart';
import '../models/name_analysis_result.dart';
import '../models/compatibility_result.dart';
import '../models/ticket_product.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const _baseUrl = 'https://fate.jiny.shop';

  static const _timeout = Duration(seconds: 60);

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
    debugPrint('[API] saveUserSaju: hasToken=${_authToken != null}, body=${jsonEncode(info.toJson())}');
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/user/saju'),
          headers: _headers,
          body: jsonEncode(info.toJson()),
        )
        .timeout(_timeout);

    debugPrint('[API] saveUserSaju: status=${response.statusCode}, body=${response.body}');
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

  Future<String> getReferralCode() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/user/referral-code'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('추천 코드 조회에 실패했습니다 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['referralCode'] as String;
  }

  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/user/apply-referral'),
          headers: _headers,
          body: jsonEncode({'referralCode': code}),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('추천 코드 적용에 실패했습니다 (${response.statusCode})');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteAccount() async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/api/user/account'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('계정 삭제에 실패했습니다 (${response.statusCode})');
    }
  }

  Future<List<Map<String, dynamic>>> getMyResults() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/user/my-results'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('저장된 결과 조회에 실패했습니다 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['results'] as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ── Ticket API ──

  Future<List<TicketProduct>> getProducts() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/tickets/products'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('상품 목록 조회에 실패했습니다 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['products'] as List;
    return list
        .map((e) => TicketProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getTicketBalance() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/tickets/balance'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('티켓 잔액 조회에 실패했습니다 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['balance'] as int;
  }

  Future<int> consumeTicket(String type) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/tickets/consume'),
          headers: _headers,
          body: jsonEncode({'type': type}),
        )
        .timeout(_timeout);

    if (response.statusCode == 402) {
      throw InsufficientTicketsException();
    }
    if (response.statusCode != 200) {
      throw Exception('티켓 소모에 실패했습니다 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['balance'] as int;
  }

  Future<int> verifyPurchase({
    required String platform,
    required String productId,
    required String purchaseToken,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/tickets/verify-purchase'),
          headers: _headers,
          body: jsonEncode({
            'platform': platform,
            'productId': productId,
            'purchaseToken': purchaseToken,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('구매 검증에 실패했습니다 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['balance'] as int;
  }

  Future<List<Map<String, dynamic>>> getTicketHistory() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/tickets/history'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('티켓 내역 조회에 실패했습니다 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['history'] as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  // ── Inquiry API ──

  Future<Map<String, dynamic>> createInquiry({
    required String category,
    required String title,
    required String content,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/inquiry'),
          headers: _headers,
          body: jsonEncode({
            'category': category,
            'title': title,
            'content': content,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('문의 등록에 실패했습니다 (${response.statusCode})');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getInquiries() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/inquiry'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('문의 목록 조회에 실패했습니다 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['inquiries'] as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<int> getUnreadInquiryCount() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/inquiry/unread-count'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      return 0;
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['count'] as int;
  }

  Future<void> markInquiryRead(int id) async {
    await http
        .put(
          Uri.parse('$_baseUrl/api/inquiry/$id/read'),
          headers: _headers,
        )
        .timeout(_timeout);
  }

  // ── Share API ──

  Future<String> shareResult({
    required String type,
    required Map<String, dynamic> data,
    String? birthDate,
    String? birthTime,
    String? gender,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'data': data,
    };
    if (birthDate != null) body['birthDate'] = birthDate;
    if (birthTime != null) body['birthTime'] = birthTime;
    if (gender != null) body['gender'] = gender;

    final response = await http
        .post(
          Uri.parse('$_baseUrl/api/share'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('공유 URL 생성에 실패했습니다 (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['shareUrl'] as String;
  }

  // ── Name History API ──

  Future<List<Map<String, dynamic>>> getNameHistory() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/api/name-analysis/history'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('성명학 히스토리 조회에 실패했습니다 (${response.statusCode})');
    }

    final list = jsonDecode(response.body) as List;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> deleteNameHistory(int id) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/api/name-analysis/history/$id'),
          headers: _headers,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('성명학 히스토리 삭제에 실패했습니다 (${response.statusCode})');
    }
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

class InsufficientTicketsException implements Exception {
  @override
  String toString() => '티켓이 부족합니다.';
}
