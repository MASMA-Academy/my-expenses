import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores a salted-hash of the user's app-lock PIN in SharedPreferences.
/// The raw PIN is never persisted.
class AppLock {
  AppLock._();

  static const _pinHashKey = 'app_lock_pin_hash';
  static const _saltKey = 'app_lock_salt';

  static Future<bool> hasPinSet() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.containsKey(_pinHashKey);
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();

    await prefs.setString(_saltKey, salt);
    await prefs.setString(_pinHashKey, _hash(pin, salt));
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_saltKey);
    final storedHash = prefs.getString(_pinHashKey);

    if (salt == null || storedHash == null) return false;

    return _hash(pin, salt) == storedHash;
  }

  static Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_pinHashKey);
    await prefs.remove(_saltKey);
  }

  static String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  static String _generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));

    return base64UrlEncode(values);
  }
}
