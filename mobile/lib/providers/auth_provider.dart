import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get displayName => _user?.displayName;
  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;

  AuthProvider() {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        updateApiToken();
      } else {
        _apiService.setAuthToken(null);
      }
      notifyListeners();
    });
  }

  /// Firebase Auth 세션 복원을 대기
  Future<void> waitForAuthReady() async {
    debugPrint('[Auth] waitForAuthReady: waiting for auth state...');
    final user = await _authService.authStateChanges.first;
    _user = user;
    debugPrint('[Auth] waitForAuthReady: user=${user?.uid}, email=${user?.email}');
    if (user != null) {
      await updateApiToken();
    }
  }

  Future<String?> getIdToken() async {
    return await _authService.getIdToken();
  }

  Future<void> updateApiToken() async {
    final token = await getIdToken();
    debugPrint('[Auth] updateApiToken: token=${token != null ? '${token.substring(0, 20)}...' : 'NULL'}');
    _apiService.setAuthToken(token);
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithGoogle();
      await updateApiToken();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signInWithApple();
      await updateApiToken();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _apiService.setAuthToken(null);
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteAccount();
      await _authService.deleteAccount();
      _apiService.setAuthToken(null);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
