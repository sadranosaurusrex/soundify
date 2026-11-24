import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  factory ApiException.fromDioException(DioException dioException) {
    int? status = dioException.response?.statusCode;
    String? code;
    String message = 'خطایی در ارتباط با سرور رخ داد.';

    if (dioException.response?.data != null &&
        dioException.response?.data is Map) {
      final data = dioException.response!.data as Map;
      if (data.containsKey('error') && data['error'] is Map) {
        final err = data['error'] as Map;
        code = err['code']?.toString();
        message = err['message']?.toString() ?? message;
      } else if (data.containsKey('message')) {
        message = data['message'].toString();
      }
    }

    // Map common server error codes to Persian messages
    if (code != null) {
      switch (code) {
        case 'invalid_credentials':
          message = 'ایمیل یا رمز عبور اشتباه است.';
          break;
        case 'account_not_verified':
          message = 'حساب کاربری شما هنوز فعال نشده است. لطفاً کد تایید را وارد کنید.';
          break;
        case 'email_already_exists':
          message = 'این ایمیل قبلاً ثبت شده است.';
          break;
        case 'username_already_exists':
          message = 'این نام کاربری قبلاً انتخاب شده است.';
          break;
        case 'invalid_otp':
          message = 'کد تایید وارد شده نامعتبر است.';
          break;
        case 'otp_expired':
          message = 'کد تایید منقضی شده است. لطفاً درخواست کد جدید دهید.';
          break;
        case 'otp_attempts_exceeded':
          message = 'تعداد تلاش‌های ناموفق بیش از حد مجاز است.';
          break;
        case 'user_not_found':
          message = 'کاربری با این مشخصات یافت نشد.';
          break;
        case 'already_favorited':
          message = 'این آهنگ قبلاً به علاقه‌مندی‌ها اضافه شده است.';
          break;
        case 'already_in_playlist':
          message = 'این آهنگ قبلاً به این پلی‌لیست افزوده شده است.';
          break;
      }
    } else {
      switch (dioException.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'مهلت اتصال به سرور به پایان رسید. لطفاً اینترنت خود را بررسی کنید.';
          break;
        case DioExceptionType.connectionError:
          message = 'عدم برقراری ارتباط با اینترنت یا سرور.';
          break;
        default:
          if (status == 401) {
            message = 'نشست کاربری شما منقضی شده است.';
          } else if (status == 404) {
            message = 'مورد درخواستی یافت نشد.';
          } else if (status == 500) {
            message = 'خطای داخلی سرور.';
          }
      }
    }

    return ApiException(
      message: message,
      code: code,
      statusCode: status,
    );
  }

  @override
  String toString() => message;
}
