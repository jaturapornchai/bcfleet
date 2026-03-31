import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// AuthService — จัดการ authentication
class AuthService {
  final FleetApiClient _api;
  static const _tokenKey = 'fleet_auth_token';
  static const _shopIdKey = 'fleet_shop_id';
  static const _userTypeKey = 'fleet_user_type';

  AuthService(this._api);

  /// Login ด้วย phone + OTP
  Future<AuthResult> loginWithOTP(String phone, String otp) async {
    final response = await _api.post('/auth/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });
    final result = AuthResult.fromJson(response.data);
    await _saveToken(result);
    _api.updateToken(result.token);
    return result;
  }

  /// ขอ OTP
  Future<void> requestOTP(String phone) async {
    await _api.post('/auth/request-otp', data: {'phone': phone});
  }

  /// ดึง token ที่เก็บไว้
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_shopIdKey);
    await prefs.remove(_userTypeKey);
  }

  Future<void> _saveToken(AuthResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, result.token);
    await prefs.setString(_shopIdKey, result.shopId);
    await prefs.setString(_userTypeKey, result.userType);
  }
}

/// ผลลัพธ์จากการ login
class AuthResult {
  final String token;
  final String userId;
  final String shopId;
  final String userType;
  final String name;

  AuthResult({
    required this.token,
    required this.userId,
    required this.shopId,
    required this.userType,
    required this.name,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      userId: json['user_id'] as String,
      shopId: json['shop_id'] as String,
      userType: json['user_type'] as String,
      name: json['name'] as String,
    );
  }
}
