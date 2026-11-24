import 'package:flutter/foundation.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import '../services/security_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final SecureStorageService secureStorageService;
  final SecurityService securityService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isBiometricEnabled = false;
  DeviceSecurityStatus? _deviceSecurity;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isBiometricEnabled => _isBiometricEnabled;
  DeviceSecurityStatus? get deviceSecurity => _deviceSecurity;

  AuthProvider({
    required this.apiClient,
    required this.secureStorageService,
    required this.securityService,
  }) {
    apiClient.onSessionExpired = () {
      _currentUser = null;
      notifyListeners();
    };
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // --- Initial Auth Check ---
  Future<bool> checkInitialAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isBiometricEnabled = await secureStorageService.isBiometricEnabled();
      _deviceSecurity = await securityService.checkDeviceSecurity();

      final token = await secureStorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        final res = await apiClient.get(ApiEndpoints.userMe);
        if (res.statusCode == 200 && res.data != null) {
          _currentUser = UserModel.fromJson(res.data as Map<String, dynamic>);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (_) {
      // If fetching /users/me fails or token is invalid, clear tokens
      await secureStorageService.clearTokens();
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- Login ---
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.post(
        ApiEndpoints.login,
        data: {'email': email.trim(), 'password': password},
      );

      if (res.statusCode == 200 && res.data != null) {
        final access = res.data['access'] as String;
        final refresh = res.data['refresh'] as String;
        final userJson = res.data['user'] as Map<String, dynamic>;

        await secureStorageService.saveTokens(access: access, refresh: refresh);
        await secureStorageService.saveUserEmail(email.trim());
        _currentUser = UserModel.fromJson(userJson);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'خطایی هنگام ورود رخ داد.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- Register ---
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.post(
        ApiEndpoints.register,
        data: {
          'email': email.trim(),
          'username': username.trim(),
          'password': password,
          if (displayName != null && displayName.isNotEmpty)
            'display_name': displayName.trim(),
        },
      );

      if (res.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'خطایی هنگام ثبت‌نام رخ داد.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- Verify OTP ---
  Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.post(
        ApiEndpoints.otpVerify,
        data: {
          'email': email.trim(),
          'code': code.trim(),
        },
      );

      if (res.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'خطایی در بررسی کد تایید رخ داد.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- Resend OTP ---
  Future<bool> resendOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.post(
        ApiEndpoints.otpRequest,
        data: {'email': email.trim()},
      );

      if (res.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'خطایی در ارسال مجدد کد رخ داد.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- Request Password Reset ---
  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.post(
        ApiEndpoints.passwordResetRequest,
        data: {'email': email.trim()},
      );

      if (res.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'خطایی در درخواست بازیابی رمز رخ داد.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- Confirm Password Reset ---
  Future<bool> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.post(
        ApiEndpoints.passwordResetConfirm,
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'new_password': newPassword,
        },
      );

      if (res.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'خطایی در تغییر رمز عبور رخ داد.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- Biometric Login ---
  Future<bool> loginWithBiometrics() async {
    final authenticated = await securityService.authenticateWithBiometrics();
    if (!authenticated) return false;

    // Check if token exists and valid
    final token = await secureStorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      try {
        final res = await apiClient.get(ApiEndpoints.userMe);
        if (res.statusCode == 200 && res.data != null) {
          _currentUser = UserModel.fromJson(res.data as Map<String, dynamic>);
          notifyListeners();
          return true;
        }
      } catch (_) {}
    }

    _errorMessage = 'نشست بیومتریک منقضی شده است؛ لطفاً با رمز عبور وارد شوید.';
    notifyListeners();
    return false;
  }

  // --- Toggle Biometrics ---
  Future<void> toggleBiometric(bool enable) async {
    if (enable) {
      final authenticated = await securityService.authenticateWithBiometrics(
        reason: 'تایید هویت جهت فعال‌سازی ورود بیومتریک',
      );
      if (authenticated) {
        await secureStorageService.setBiometricEnabled(true);
        _isBiometricEnabled = true;
      }
    } else {
      await secureStorageService.setBiometricEnabled(false);
      _isBiometricEnabled = false;
    }
    notifyListeners();
  }

  // --- Update Profile ---
  Future<bool> updateProfile({String? displayName, String? avatarUrl}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.patch(
        ApiEndpoints.userMe,
        data: {
          if (displayName != null) 'display_name': displayName.trim(),
          if (avatarUrl != null) 'avatar_url': avatarUrl.trim(),
        },
      );

      if (res.statusCode == 200 && res.data != null) {
        _currentUser = UserModel.fromJson(res.data as Map<String, dynamic>);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'خطایی در ویرایش مشخصات رخ داد.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // --- Refresh Device Security Status ---
  Future<void> refreshDeviceSecurity() async {
    _deviceSecurity = await securityService.checkDeviceSecurity();
    notifyListeners();
  }

  // --- Logout ---
  Future<void> logout() async {
    try {
      final refreshToken = await secureStorageService.getRefreshToken();
      await apiClient.post(
        ApiEndpoints.logout,
        data: {
          'refresh': ?refreshToken,
        },
      );
    } catch (_) {}

    await secureStorageService.clearTokens();
    _currentUser = null;
    notifyListeners();
  }
}
