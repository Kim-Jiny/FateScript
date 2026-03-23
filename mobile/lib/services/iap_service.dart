import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class IapService {
  static final IapService _instance = IapService._internal();
  factory IapService() => _instance;
  IapService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final ApiService _api = ApiService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Map<String, ProductDetails> _products = {};
  bool _available = false;

  /// 구매 성공 후 잔액을 전달하는 콜백
  void Function(int balance)? onBalanceUpdated;
  void Function(String error)? onPurchaseError;
  VoidCallback? onPurchaseCanceled;

  Map<String, ProductDetails> get products => _products;
  bool get isAvailable => _available;

  Future<void> initialize({Set<String>? productIds}) async {
    debugPrint('[IAP] ===== 초기화 시작 =====');
    debugPrint('[IAP] Platform: ${Platform.operatingSystem}');
    try {
      _available = await _iap.isAvailable();
      debugPrint('[IAP] Store available: $_available');
    } catch (e) {
      debugPrint('[IAP] isAvailable() failed: $e');
      _available = false;
      return;
    }

    if (!_available) {
      debugPrint('[IAP] Store not available — 시뮬레이터이거나 StoreKit 설정 누락');
      return;
    }

    // 구매 스트림 구독
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (error) {
        debugPrint('[IAP] Purchase stream error: $error');
      },
    );
    debugPrint('[IAP] Purchase stream 구독 완료');

    // 상품 로드
    try {
      final ids = productIds ?? <String>{};
      debugPrint('[IAP] 조회할 상품 ID 목록 (${ids.length}개): $ids');
      if (ids.isEmpty) {
        debugPrint('[IAP] 상품 ID가 비어있음 — 서버에서 상품이 로드되지 않았을 수 있음');
        return;
      }
      final response = await _iap.queryProductDetails(ids);

      if (response.error != null) {
        debugPrint('[IAP] Query products error: ${response.error}');
        debugPrint('[IAP] Error code: ${response.error!.code}');
        debugPrint('[IAP] Error message: ${response.error!.message}');
        debugPrint('[IAP] Error details: ${response.error!.details}');
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('[IAP] 스토어에서 찾지 못한 상품 ID: ${response.notFoundIDs}');
        debugPrint('[IAP] → App Store Connect / Google Play Console에서 상품이 등록되어 있는지 확인하세요');
        debugPrint('[IAP] → 상품 ID가 정확히 일치하는지 확인하세요');
        debugPrint('[IAP] → iOS: Xcode StoreKit Configuration 파일이 설정되어 있는지 확인하세요');
      }

      _products = {
        for (final p in response.productDetails) p.id: p,
      };

      debugPrint('[IAP] 로드된 상품 ${_products.length}개: ${_products.keys.join(', ')}');
      for (final p in response.productDetails) {
        debugPrint('[IAP]   - ${p.id}: ${p.title} (${p.price})');
      }
      debugPrint('[IAP] ===== 초기화 완료 =====');
    } catch (e, stack) {
      debugPrint('[IAP] Product query 예외: $e');
      debugPrint('[IAP] Stack trace: $stack');
    }
  }

  Future<bool> buyProduct(String productId) async {
    debugPrint('[IAP] 구매 시도 — productId: $productId');
    debugPrint('[IAP] 현재 로드된 상품: ${_products.keys.toList()}');
    final product = _products[productId];
    if (product == null) {
      debugPrint('[IAP] 상품을 찾을 수 없음: $productId');
      debugPrint('[IAP] → 스토어에서 상품이 로드되지 않았습니다. 상품 등록 상태를 확인하세요.');
      return false;
    }

    debugPrint('[IAP] 구매 진행 — ${product.title} (${product.price})');
    final purchaseParam = PurchaseParam(productDetails: product);
    return await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    debugPrint('[IAP] ===== 구매 상태 업데이트 =====');
    debugPrint('[IAP] status: ${purchase.status}');
    debugPrint('[IAP] productID: ${purchase.productID}');
    debugPrint('[IAP] purchaseID: ${purchase.purchaseID}');
    debugPrint('[IAP] pendingCompletePurchase: ${purchase.pendingCompletePurchase}');
    debugPrint('[IAP] verificationData source: ${purchase.verificationData.source}');
    debugPrint('[IAP] serverVerificationData 길이: ${purchase.verificationData.serverVerificationData.length}');

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // 서버에서 검증 (최대 3회 재시도)
      final platform = Platform.isIOS ? 'ios' : 'android';
      debugPrint('[IAP] 서버 검증 요청 — platform: $platform, productId: ${purchase.productID}');

      bool verified = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final balance = await _api.verifyPurchase(
            platform: platform,
            productId: purchase.productID,
            purchaseToken: purchase.verificationData.serverVerificationData,
          );

          debugPrint('[IAP] 서버 검증 성공! 잔액: $balance (시도 $attempt/3)');
          onBalanceUpdated?.call(balance);
          verified = true;
          break;
        } catch (e) {
          debugPrint('[IAP] 서버 검증 실패 (시도 $attempt/3): $e');
          if (attempt < 3) {
            await Future.delayed(Duration(seconds: 2 * attempt));
          }
        }
      }

      // 검증 성공/실패 모두 completePurchase 호출하여 pending 상태 해제
      if (purchase.pendingCompletePurchase) {
        debugPrint('[IAP] completePurchase 호출 (verified: $verified)');
        await _iap.completePurchase(purchase);
      }

      if (!verified) {
        // 실패한 구매 정보를 로컬에 저장하여 나중에 수동 복구 가능
        await _saveFailedPurchase(platform, purchase.productID,
            purchase.verificationData.serverVerificationData);
        onPurchaseError?.call('구매 검증에 실패했습니다. 앱을 재시작하면 자동으로 재시도됩니다.');
      }
    } else if (purchase.status == PurchaseStatus.error) {
      debugPrint('[IAP] 구매 에러: ${purchase.error}');
      debugPrint('[IAP] 에러 코드: ${purchase.error?.code}');
      debugPrint('[IAP] 에러 메시지: ${purchase.error?.message}');
      debugPrint('[IAP] 에러 상세: ${purchase.error?.details}');
      onPurchaseError?.call('구매 중 오류가 발생했습니다.');
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    } else if (purchase.status == PurchaseStatus.canceled) {
      debugPrint('[IAP] 구매 취소됨');
      onPurchaseCanceled?.call();
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    } else if (purchase.status == PurchaseStatus.pending) {
      debugPrint('[IAP] 구매 대기 중 (결제 승인 대기)');
    }
    debugPrint('[IAP] ===== 구매 처리 완료 =====');
  }

  /// 검증 실패한 구매를 로컬에 저장
  Future<void> _saveFailedPurchase(String platform, String productId, String purchaseToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('failed_purchases') ?? [];
      final entry = jsonEncode({
        'platform': platform,
        'productId': productId,
        'purchaseToken': purchaseToken,
        'failedAt': DateTime.now().toIso8601String(),
      });
      // 중복 방지
      if (!list.any((e) {
        final m = jsonDecode(e) as Map<String, dynamic>;
        return m['purchaseToken'] == purchaseToken;
      })) {
        list.add(entry);
        await prefs.setStringList('failed_purchases', list);
        debugPrint('[IAP] 실패한 구매 저장 완료 (총 ${list.length}건)');
      }
    } catch (e) {
      debugPrint('[IAP] 실패 구매 저장 오류: $e');
    }
  }

  /// 저장된 실패 구매를 다시 검증 시도
  Future<int> retryFailedPurchases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('failed_purchases') ?? [];
      if (list.isEmpty) return 0;

      debugPrint('[IAP] 실패 구매 재시도 시작 (${list.length}건)');
      final remaining = <String>[];
      int recovered = 0;

      for (final entry in list) {
        final m = jsonDecode(entry) as Map<String, dynamic>;
        try {
          final balance = await _api.verifyPurchase(
            platform: m['platform'] as String,
            productId: m['productId'] as String,
            purchaseToken: m['purchaseToken'] as String,
          );
          debugPrint('[IAP] 실패 구매 복구 성공! productId: ${m['productId']}, 잔액: $balance');
          onBalanceUpdated?.call(balance);
          recovered++;
        } catch (e) {
          debugPrint('[IAP] 실패 구매 복구 실패: ${m['productId']} — $e');
          remaining.add(entry);
        }
      }

      await prefs.setStringList('failed_purchases', remaining);
      debugPrint('[IAP] 실패 구매 재시도 완료 — 복구: $recovered, 잔여: ${remaining.length}');
      return recovered;
    } catch (e) {
      debugPrint('[IAP] retryFailedPurchases 오류: $e');
      return 0;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
