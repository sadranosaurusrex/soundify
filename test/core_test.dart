import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundify/core/constants/api_endpoints.dart';
import 'package:soundify/core/constants/app_colors.dart';
import 'package:soundify/core/storage/secure_storage_service.dart';
import 'package:soundify/core/theme/app_theme.dart';
import 'package:soundify/core/utils/debounce.dart';

/// حافظه شبیه‌سازی‌شده در RAM برای تست کردن SecureStorageService بدون نیاز به گوشی واقعی
class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

void main() {
  group('ApiEndpoints Tests', () {
    test('trackStream builds the full stream URL with track ID', () {
      // Arrange
      const trackId = 'T-123';

      // Act
      final url = ApiEndpoints.trackStream(trackId);

      // Assert
      expect(
        url,
        equals('https://soundify.easyfound.ir/api/v1/tracks/T-123/stream'),
      );
    });
  });

  group('AppTheme Tests', () {
    test('darkTheme has dark brightness and dark background', () {
      // Act
      final theme = AppTheme.darkTheme;

      // Assert
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.darkBackground));
      expect(theme.colorScheme.primary, equals(AppColors.primary));
    });

    test('lightTheme has light brightness and light background', () {
      // Act
      final theme = AppTheme.lightTheme;

      // Assert
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.lightBackground));
      expect(theme.colorScheme.primary, equals(AppColors.primary));
    });
  });

  group('Debounce Tests', () {
    testWidgets('executes action only after delay has passed', (tester) async {
      // Arrange
      final debounce = Debounce(delay: const Duration(milliseconds: 500));
      var callCount = 0;

      // Act
      debounce.run(() => callCount++);

      // قبل از تمام شدن 500ms نباید اجرا شده باشد
      await tester.pump(const Duration(milliseconds: 400));
      expect(callCount, equals(0));

      // با گذشت 100ms باقی‌مانده (جمعاً 500ms)، باید دقیقاً یک بار اجرا شود
      await tester.pump(const Duration(milliseconds: 100));
      expect(callCount, equals(1));

      debounce.dispose();
    });

    testWidgets('cancels previous timer on rapid calls and runs only the last one', (tester) async {
      // Arrange
      final debounce = Debounce(delay: const Duration(milliseconds: 500));
      String? lastQuery;
      var callCount = 0;

      // Act: شبیه‌سازی تایپ سریع کاربر ("ا" -> "اب" -> "ابی")
      debounce.run(() {
        callCount++;
        lastQuery = 'ا';
      });
      await tester.pump(const Duration(milliseconds: 200));

      debounce.run(() {
        callCount++;
        lastQuery = 'اب';
      });
      await tester.pump(const Duration(milliseconds: 200));

      debounce.run(() {
        callCount++;
        lastQuery = 'ابی';
      });

      // تا این لحظه (فقط بعد از آخرین تایپ، 400ms می‌گذرد) هنوز نباید اجرا شود
      await tester.pump(const Duration(milliseconds: 400));
      expect(callCount, equals(0));

      // بعد از 100ms دیگر (500ms از آخرین فراخوانی)، فقط آخرین مورد اجرا می‌شود
      await tester.pump(const Duration(milliseconds: 100));
      expect(callCount, equals(1));
      expect(lastQuery, equals('ابی'));

      debounce.dispose();
    });

    testWidgets('dispose cancels pending timer so action never runs', (tester) async {
      // Arrange
      final debounce = Debounce(delay: const Duration(milliseconds: 500));
      var wasCalled = false;

      // Act
      debounce.run(() => wasCalled = true);
      await tester.pump(const Duration(milliseconds: 200));
      debounce.dispose();

      // حتی اگر زمان زیادی هم بگذرد، نباید اجرا شود
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(wasCalled, isFalse);
    });
  });

  group('SecureStorageService Tests', () {
    late _FakeSecureStorage fakeStorage;
    late SecureStorageService service;

    setUp(() {
      fakeStorage = _FakeSecureStorage();
      service = SecureStorageService(storage: fakeStorage);
      SharedPreferences.setMockInitialValues({});
    });

    test('saveTokens stores both tokens and getters retrieve them', () async {
      // Arrange & Act
      await service.saveTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
      );

      // Assert
      expect(await service.getAccessToken(), equals('access_123'));
      expect(await service.getRefreshToken(), equals('refresh_456'));
    });

    test('clearTokens removes both access and refresh tokens', () async {
      // Arrange
      await service.saveTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
      );

      // Act
      await service.clearTokens();

      // Assert
      expect(await service.getAccessToken(), isNull);
      expect(await service.getRefreshToken(), isNull);
    });

    test('isBiometricEnabled defaults to false and persists changes', () async {
      // Initial state
      expect(await service.isBiometricEnabled(), isFalse);

      // Enable
      await service.setBiometricEnabled(true);
      expect(await service.isBiometricEnabled(), isTrue);

      // Disable
      await service.setBiometricEnabled(false);
      expect(await service.isBiometricEnabled(), isFalse);
    });

    test('hasSeenOnboarding defaults to false and becomes true after setOnboardingSeen', () async {
      // Initial state
      expect(await service.hasSeenOnboarding(), isFalse);

      // Mark as seen
      await service.setOnboardingSeen();
      expect(await service.hasSeenOnboarding(), isTrue);
    });
  });
}
