import 'package:dio/dio.dart';

/// استثنای اختصاصی این پروژه — همه خطاهای شبکه به این تبدیل می‌شوند.
/// [message]: پیام فارسی قابل‌نمایش به کاربر
/// [statusCode]: کد HTTP (ممکن است null باشد، مثلاً خطای قطع اینترنت)
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.statusCode,
  });

  /// مترجم اصلی: هر DioException خام را به ApiException فارسی تبدیل می‌کند
  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      // اینترنت قطع است یا DNS جواب نداد
      case DioExceptionType.connectionError:
        return const ApiException(
          message: 'اتصال به اینترنت برقرار نیست.',
        );

      // سرور در بازه زمانی مشخص جواب نداد
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException(
          message: 'سرور پاسخگو نیست. لطفاً دوباره تلاش کنید.',
        );

      // سرور جواب داد، ولی کد خطا فرستاد (4xx یا 5xx)
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        final message = _extractMessage(data, statusCode);
        return ApiException(message: message, statusCode: statusCode);

      // درخواست توسط برنامه لغو شد (مثلاً کاربر صفحه را بست)
      case DioExceptionType.cancel:
        return const ApiException(message: 'درخواست لغو شد.');

      default:
        return const ApiException(message: 'خطای ناشناخته‌ای رخ داد.');
    }
  }

  /// استخراج پیام خطا از body پاسخ سرور
  /// سرور ممکن است به سه شکل مختلف خطا بفرستد:
  ///   ۱. {"detail": "پیام"}
  ///   ۲. {"message": "پیام"}
  ///   ۳. {"email": ["این ایمیل قبلاً ثبت شده است."]}
  static String _extractMessage(dynamic data, int? statusCode) {
    // اگر body اصلاً وجود نداشت یا Map نبود، از کد وضعیت پیام می‌سازیم
    if (data is! Map<String, dynamic>) {
      return _messageFromStatusCode(statusCode);
    }

    // حالت ۱ و ۲: کلیدهای استاندارد
    if (data['detail'] != null) return data['detail'].toString();
    if (data['message'] != null) return data['message'].toString();

    // حالت ۳: خطای فیلد-به-فیلد مثل {"email": ["ایمیل تکراری است"]}
    if (data.isNotEmpty) {
      final firstValue = data.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
      return firstValue.toString();
    }

    return _messageFromStatusCode(statusCode);
  }

  /// تبدیل کد وضعیت HTTP به پیام فارسی قابل‌فهم
  static String _messageFromStatusCode(int? code) {
    switch (code) {
      case 400:
        return 'اطلاعات وارد شده نامعتبر است.';
      case 401:
        return 'احراز هویت ناموفق بود. لطفاً دوباره وارد شوید.';
      case 403:
        return 'شما به این بخش دسترسی ندارید.';
      case 404:
        return 'محتوای درخواستی یافت نشد.';
      case 429:
        return 'تعداد درخواست‌ها بیش از حد مجاز است. کمی صبر کنید.';
      case 500:
      case 502:
      case 503:
        return 'خطای داخلی سرور. لطفاً بعداً امتحان کنید.';
      default:
        return 'خطای ناشناخته‌ای رخ داد.';
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
