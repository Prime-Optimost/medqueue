import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

// Provider class for managing authentication state across the Flutter app.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  String? _token;

  UserModel? get user => _user;
  String? get token => _token;

  bool get isAuthenticated => _token != null;

  Future<int?> register(UserModel userModel, String password) async {
    final result = await _authService.register(userModel, password);
    return result;
  }

  Future<bool> verifyOtp(String userId, String otp) async {
    final response = await _authService.verifyOTP(userId, otp);
    return response;
  }

  Future<bool> login(String username, String password) async {
    final authResult = await _authService.login(username, password);
    if (authResult != null) {
      _user = authResult['user'];
      _token = authResult['token'];
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> checkAuthStatus() async {
    final isValid = await _authService.checkAuthStatus();
    if (isValid) {
      // Token is valid, but we need to get user details if not already set
      // For now, assume user is set from login
      // In production, you might want to fetch user details from token
    } else {
      _user = null;
      _token = null;
    }
    notifyListeners();
    return isValid;
  }

  Future<void> logout() async {
    if (_token != null) {
      await _authService.logout(_token!);
    }
    _user = null;
    _token = null;
    notifyListeners();
  }
}
