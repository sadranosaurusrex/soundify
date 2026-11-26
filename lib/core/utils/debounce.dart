import 'dart:async';

/// هر بار که run() صدا زده میشه، تایمر قبلی کنسل و از نو شروع میشه.
/// بعد از [delay]، اگه run() دیگه‌ای نیومد، اکشن اجرا میشه.
class Debounce {
  final Duration delay;
  Timer? _timer;

  Debounce({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();         // تایمر قبلی رو بکش
    _timer = Timer(delay, action);  // تایمر جدید بساز
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

// VoidCallback = typedef void Function() — از flutter/foundation میاد
// اما چون ما flutter import نداریم، باید اضافه کنیم:
typedef VoidCallback = void Function();
