import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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

  Map<String, ProductDetails> get products => _products;
  bool get isAvailable => _available;

  Future<void> initialize({Set<String>? productIds}) async {
    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      debugPrint('[IAP] isAvailable() failed: $e');
      _available = false;
      return;
    }

    if (!_available) {
      debugPrint('[IAP] Store not available');
      return;
    }

    // 구매 스트림 구독
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (error) {
        debugPrint('[IAP] Purchase stream error: $error');
      },
    );

    // 상품 로드
    try {
      final ids = productIds ?? <String>{};
      if (ids.isEmpty) return;
      final response = await _iap.queryProductDetails(ids);

      if (response.error != null) {
        debugPrint('[IAP] Query products error: ${response.error}');
      }

      _products = {
        for (final p in response.productDetails) p.id: p,
      };

      debugPrint('[IAP] Loaded ${_products.length} products: ${_products.keys.join(', ')}');
    } catch (e) {
      debugPrint('[IAP] Product query failed: $e');
    }
  }

  Future<bool> buyProduct(String productId) async {
    final product = _products[productId];
    if (product == null) {
      debugPrint('[IAP] Product not found: $productId');
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    return await _iap.buyConsumable(purchaseParam: purchaseParam);
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchase in purchaseDetailsList) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      // 서버에서 검증
      try {
        final balance = await _api.verifyPurchase(
          platform: Platform.isIOS ? 'ios' : 'android',
          productId: purchase.productID,
          purchaseToken: purchase.verificationData.serverVerificationData,
        );

        onBalanceUpdated?.call(balance);

        // 검증 성공 후 완료 처리
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } catch (e) {
        debugPrint('[IAP] Server verification failed: $e');
        onPurchaseError?.call('구매 검증에 실패했습니다. 앱을 재시작해 주세요.');
        // 서버 검증 실패 시 completePurchase 호출하지 않음
        // → 다음 앱 실행 시 재전달됨
      }
    } else if (purchase.status == PurchaseStatus.error) {
      debugPrint('[IAP] Purchase error: ${purchase.error}');
      onPurchaseError?.call('구매 중 오류가 발생했습니다.');
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    } else if (purchase.status == PurchaseStatus.canceled) {
      debugPrint('[IAP] Purchase canceled');
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
