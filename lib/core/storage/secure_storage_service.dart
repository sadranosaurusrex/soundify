import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keySavedEmail = 'saved_email';
  static const _keyOnboardingSeen = 'has_seen_onboarding';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // --- Secure Tokens ---
  Future<void> saveTokens({required String access, required String refresh}) async {
    await _secureStorage.write(key: _keyAccessToken, value: access);
    await _secureStorage.write(key: _keyRefreshToken, value: refresh);
  }

  Future<void> saveAccessToken(String access) async {
    await _secureStorage.write(key: _keyAccessToken, value: access);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
  }

  // --- Biometrics & Security ---
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _secureStorage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  Future<void> saveUserEmail(String email) async {
    await _secureStorage.write(key: _keySavedEmail, value: email);
  }

  Future<String?> getSavedUserEmail() async {
    return await _secureStorage.read(key: _keySavedEmail);
  }

  // --- SharedPreferences for non-sensitive app settings ---
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingSeen) ?? false;
  }

  Future<void> setOnboardingSeen(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingSeen, seen);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
