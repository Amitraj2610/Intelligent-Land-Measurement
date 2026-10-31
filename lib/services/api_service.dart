import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _customHostKey = 'api_custom_base_url';
  static String? _cachedBaseUrl;
  static bool? _isDatabaseConnected;

  /// Default candidate hosts based on platform
  static List<String> get _candidateUrls {
    if (kIsWeb) {
      return ['http://127.0.0.1:5000', 'http://localhost:5000'];
    }

    try {
      if (Platform.isAndroid) {
        return [
          'http://172.16.38.247:5000', // Current Wi-Fi LAN address
          'http://192.168.137.1:5000', // Wi-Fi Hotspot / alternate LAN
          'http://10.92.187.32:5000',  // Alternate Wi-Fi LAN address
          'http://127.0.0.1:5000',   // ADB reverse-port forward (Fastest, zero-latency)
          'http://localhost:5000',   // Localhost via ADB reverse
          'http://10.0.2.2:5000',    // Standard Android Emulator loopback
          'http://192.168.1.4:5000', // Computer Wi-Fi LAN address
          'http://192.168.1.3:5000', // Alternate device/LAN address
          'http://192.168.1.2:5000',
          'http://192.168.1.5:5000',
          'http://192.168.1.6:5000',
          'http://192.168.1.7:5000',
          'http://192.168.1.8:5000',
          'http://192.168.1.9:5000',
          'http://192.168.1.10:5000',
        ];
      }
    } catch (_) {}

    return [
      'http://172.16.38.247:5000',
      'http://192.168.137.1:5000',
      'http://10.92.187.32:5000',
      'http://127.0.0.1:5000',
      'http://localhost:5000',
      'http://192.168.1.4:5000',
      'http://192.168.1.3:5000',
    ];
  }

  /// Get current working or configured base URL
  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;

    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_customHostKey);
    if (custom != null && custom.trim().isNotEmpty) {
      final clean = custom.trim();
      // Verify if custom URL is responsive
      try {
        final res = await http
            .get(Uri.parse('$clean/api/health'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200 || res.statusCode == 503) {
          _cachedBaseUrl = clean;
          _isDatabaseConnected = (res.statusCode == 200);
          return _cachedBaseUrl!;
        }
      } catch (_) {
        // Custom URL unreachable, fall through to auto-detect
      }
    }

    // Fast parallel probe across candidate URLs
    final completer = Completer<String?>();
    int pending = _candidateUrls.length;

    for (final candidate in _candidateUrls) {
      http
          .get(Uri.parse('$candidate/api/health'))
          .timeout(const Duration(milliseconds: 1800))
          .then((res) {
        if (!completer.isCompleted &&
            (res.statusCode == 200 || res.statusCode == 503)) {
          _isDatabaseConnected = (res.statusCode == 200);
          completer.complete(candidate);
        }
      }).catchError((_) {
        // ignore errors
      }).whenComplete(() {
        pending--;
        if (pending <= 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    final detected = await completer.future;
    if (detected != null) {
      _cachedBaseUrl = detected;
      return detected;
    }

    // Fallback default
    const fallback = 'http://192.168.1.4:5000';
    _cachedBaseUrl = fallback;
    return fallback;
  }

  /// Override the backend URL manually (e.g. for custom Wi-Fi network)
  static Future<void> setCustomBaseUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_customHostKey);
      _cachedBaseUrl = null;
    } else {
      String clean = url.trim();
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        clean = 'http://$clean';
      }
      if (clean.endsWith('/')) {
        clean = clean.substring(0, clean.length - 1);
      }
      await prefs.setString(_customHostKey, clean);
      _cachedBaseUrl = clean;
    }
  }

  /// Check connectivity to backend & MongoDB database
  static Future<bool> checkConnection() async {
    try {
      final base = await getBaseUrl();
      final res = await http
          .get(Uri.parse('$base/api/health'))
          .timeout(const Duration(seconds: 3));
      final isOk = (res.statusCode == 200);
      _isDatabaseConnected = isOk;
      return isOk;
    } catch (_) {
      // If cached host failed, invalidate and retry candidates
      _cachedBaseUrl = null;
      try {
        final newBase = await getBaseUrl();
        final res = await http
            .get(Uri.parse('$newBase/api/health'))
            .timeout(const Duration(seconds: 2));
        final isOk = (res.statusCode == 200);
        _isDatabaseConnected = isOk;
        return isOk;
      } catch (_) {
        _isDatabaseConnected = false;
        return false;
      }
    }
  }

  static bool? get lastKnownConnectionStatus => _isDatabaseConnected;

  // =========================================================================
  // AUTHENTICATION (MongoDB Users Collection)
  // =========================================================================

  /// Register a new user in MongoDB
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final base = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$base/api/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim().toLowerCase(),
              'phone': phone.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ??
              'Registration failed with code ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: Unable to reach backend server.'
      };
    }
  }

  /// Login and verify credentials against MongoDB
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final base = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$base/api/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final Map<String, dynamic> data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Invalid credentials or user not registered'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: Unable to reach backend server.'
      };
    }
  }

  // =========================================================================
  // LAND MEASUREMENTS (MongoDB Lands Collection)
  // =========================================================================

  /// Fetch all saved land measurements from MongoDB for user
  static Future<List<Map<String, dynamic>>> getLands(String email) async {
    try {
      final base = await getBaseUrl();
      final cleanEmail = Uri.encodeComponent(email.trim().toLowerCase());
      final response = await http
          .get(Uri.parse('$base/api/lands/$cleanEmail'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Save or update land measurement in MongoDB
  static Future<Map<String, dynamic>> saveLand(
      Map<String, dynamic> landData) async {
    try {
      final base = await getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$base/api/lands'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(landData),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to save land'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection error: Failed to save land data.'
      };
    }
  }

  /// Delete land measurement from MongoDB
  static Future<bool> deleteLand(String id) async {
    try {
      final base = await getBaseUrl();
      final response = await http
          .delete(Uri.parse('$base/api/lands/$id'))
          .timeout(const Duration(seconds: 6));
      return (response.statusCode == 200);
    } catch (_) {
      return false;
    }
  }
}
