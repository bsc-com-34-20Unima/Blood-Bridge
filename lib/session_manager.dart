import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  /// Saves all critical donor data after login
  static Future<void> saveLoginData({
    required int donorId,
    required String token,
    required String email,
    String? name,
    String role = 'donor',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt('donorId', donorId),
      prefs.setString('token', token),
      prefs.setString('donorEmail', email),
      if (name != null) prefs.setString('donorName', name),
      prefs.setString('role', role),
    ]);
  }

  /// Retrieves stored donor ID
  static Future<int?> getDonorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('donorId');
  }

  /// Retrieves auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Clears all session data (logout/account deletion)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Checks if user is authenticated
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('donorId') && prefs.containsKey('token');
  }
}