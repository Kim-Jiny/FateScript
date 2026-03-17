import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/iap_service.dart';

class TicketProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final IapService _iap = IapService();

  int? _balance;
  bool _isPurchasing = false;
  String? _error;

  int? get balance => _balance;
  bool get isPurchasing => _isPurchasing;
  String? get error => _error;
  IapService get iapService => _iap;

  Future<void> initialize() async {
    await _iap.initialize();
    _iap.onBalanceUpdated = (balance) {
      _balance = balance;
      _isPurchasing = false;
      notifyListeners();
    };
    _iap.onPurchaseError = (error) {
      _error = error;
      _isPurchasing = false;
      notifyListeners();
    };
  }

  Future<void> loadBalance() async {
    try {
      _balance = await _api.getTicketBalance();
      notifyListeners();
    } catch (e) {
      debugPrint('[TicketProvider] loadBalance error: $e');
    }
  }

  /// 티켓 1장 소모. 성공 시 true 반환, 부족 시 InsufficientTicketsException throw
  Future<bool> consumeTicket(String type) async {
    try {
      final newBalance = await _api.consumeTicket(type);
      _balance = newBalance;
      notifyListeners();
      return true;
    } on InsufficientTicketsException {
      _balance = 0;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> buyProduct(String productId) async {
    _isPurchasing = true;
    _error = null;
    notifyListeners();

    final started = await _iap.buyProduct(productId);
    if (!started) {
      _isPurchasing = false;
      _error = '구매를 시작할 수 없습니다.';
      notifyListeners();
    }
    // 구매 결과는 IAP 콜백을 통해 전달됨
  }

  void clearBalance() {
    _balance = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
