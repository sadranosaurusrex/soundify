import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سرویس مدیریت ذخیره‌سازی امن داده‌های حساس (توکن‌ها و بیومتریک)
/// و تنظیمات غیرحساس اپلیکیشن (مثل وضعیت مشاهده Onboarding).
class SecureStorageService {
  // کلیدهای ذخیره‌سازی به صورت ثابت تعریف می‌شوند تا از خطای تایپی جلوگیری شود
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _onboardingSeenKey = 'onboarding_seen';

  final FlutterSecureStorage _storage;

  // استفاده از Constructor Injection برای اینکه در تست‌ها بتوانیم
  // یک نسخه Mock/جایگزین به این کلاس پاس بدهیم
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  // --- مدیریت توکن‌ها (Token Management) ---

  /// ذخیره هم‌زمان Access Token و Refresh Token در حافظه امن
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  /// خواندن Access Token (در صورت نبودن، null برمی‌گرداند)
  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  /// خواندن Refresh Token (در صورت نبودن، null برمی‌گرداند)
  Future<String?> getRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  /// پاک کردن هر دو توکن هنگام خروج (Logout) یا منقضی شدن نشست
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  // --- تنظیمات بیومتریک (Biometric Lock) ---

  /// بررسی اینکه آیا قفل بیومتریک (اثر انگشت / چهره) فعال شده است یا خیر
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  /// فعال یا غیرفعال کردن ورود بیومتریک
  Future<void> setBiometricEnabled(bool enabled) {
    return _storage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  // --- وضعیت صفحات معرفی (Onboarding) ---

  /// بررسی اینکه آیا کاربر قبلاً صفحات خوش‌آمدگویی را دیده است یا خیر
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  /// ثبت اینکه کاربر صفحات معرفی را دیده است
  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }
}
