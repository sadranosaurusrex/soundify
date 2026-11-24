import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService secureStorageService;
  void Function()? onSessionExpired;

  ApiClient({
    required this.secureStorageService,
    this.onSessionExpired,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'SoundifyApp/1.0 (Flutter; Android)',
        },
      ),
    );

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // If authorization header is not explicitly set, fetch token
          if (!options.headers.containsKey('Authorization')) {
            final token = await secureStorageService.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Handle automatic token refresh on 401
          final isAuthEndpoint = error.requestOptions.path.contains('/auth/login') ||
              error.requestOptions.path.contains('/auth/token/refresh') ||
              error.requestOptions.path.contains('/auth/register');

          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            final refreshToken = await secureStorageService.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Create a standalone Dio instance to avoid interceptor recursion
                final refreshDio = Dio(
                  BaseOptions(
                    baseUrl: ApiEndpoints.baseUrl,
                    headers: {'Content-Type': 'application/json'},
                  ),
                );

                final response = await refreshDio.post(
                  ApiEndpoints.tokenRefresh,
                  data: {'refresh': refreshToken},
                );

                if (response.statusCode == 200 && response.data != null) {
                  final newAccess = response.data['access'] as String;
                  final newRefresh = response.data['refresh'] as String;

                  await secureStorageService.saveTokens(
                    access: newAccess,
                    refresh: newRefresh,
                  );

                  // Update header for retry
                  final requestOptions = error.requestOptions;
                  requestOptions.headers['Authorization'] = 'Bearer $newAccess';

                  // Retry the original failed request
                  final retryResponse = await dio.fetch(requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (_) {
                // Refresh failed: session expired
                await secureStorageService.clearTokens();
                onSessionExpired?.call();
              }
            } else {
              await secureStorageService.clearTokens();
              onSessionExpired?.call();
            }
          }

          return handler.reject(error);
        },
      ),
    );
  }

  // --- Convenience HTTP Methods ---
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
