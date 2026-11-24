import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class DeviceSecurityStatus {
  final bool isRooted;
  final bool isEmulator;
  final bool canUseBiometrics;
  final List<BiometricType> availableBiometrics;

  DeviceSecurityStatus({
    required this.isRooted,
    required this.isEmulator,
    required this.canUseBiometrics,
    required this.availableBiometrics,
  });

  bool get isSecure => !isRooted && !isEmulator;
}

class SecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // --- Biometric Authentication ---
  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics({
    String reason = 'لطفاً هویت خود را با اثر انگشت یا چهره تایید کنید',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // --- Device Security: Root & Emulator Detection ---
  Future<DeviceSecurityStatus> checkDeviceSecurity() async {
    bool isRooted = false;
    bool isEmulator = false;

    if (!kIsWeb && Platform.isAndroid) {
      isRooted = _checkAndroidRoot();
      isEmulator = _checkAndroidEmulator();
    }

    final canBio = await canAuthenticateWithBiometrics();
    final biometrics = await getAvailableBiometrics();

    return DeviceSecurityStatus(
      isRooted: isRooted,
      isEmulator: isEmulator,
      canUseBiometrics: canBio,
      availableBiometrics: biometrics,
    );
  }

  bool _checkAndroidRoot() {
    // Check known root binaries / su paths
    final suPaths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
    ];

    for (final path in suPaths) {
      if (File(path).existsSync()) {
        return true;
      }
    }

    // Try executing su if possible
    try {
      final res = Process.runSync('which', ['su']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  bool _checkAndroidEmulator() {
    // Common emulator file markers or environment cues
    final emulatorPaths = [
      '/dev/socket/qemud',
      '/dev/qemu_pipe',
    ];

    for (final path in emulatorPaths) {
      if (File(path).existsSync()) {
        return true;
      }
    }

    return false;
  }
}
