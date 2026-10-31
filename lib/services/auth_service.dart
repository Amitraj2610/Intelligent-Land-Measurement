import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyEmail = 'auth_user_email';
  static const String _keyName = 'auth_user_name';
  static const String _keyPhone = 'auth_user_phone';
  static const String _keyIsLoggedIn = 'auth_is_logged_in';

  /// Save session after successful register/login
  static Future<void> saveUserSession({
    required String email,
    String? name,
    String? phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email.trim().toLowerCase());
    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString(_keyName, name.trim());
    } else {
      await prefs.setString(_keyName, email.split('@').first);
    }
    if (phone != null) {
      await prefs.setString(_keyPhone, phone.trim());
    }
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Check if user has an active session
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Get logged-in user email (defaults to fallback if not set)
  static Future<String> getCurrentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail) ?? 'farmer@example.com';
  }

  /// Get logged-in user display name
  static Future<String> getCurrentName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName);
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }
    final email = prefs.getString(_keyEmail);
    if (email != null && email.contains('@')) {
      final part = email.split('@').first;
      return part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : 'User';
    }
    return 'User';
  }

  /// Get user phone
  static Future<String> getCurrentPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone) ?? '';
  }

  /// Clear session
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    // Keep email for convenient re-login autofill if desired
  }
}
