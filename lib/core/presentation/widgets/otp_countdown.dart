import 'dart:async';

import 'package:flutter/foundation.dart';

/// A local resend clock. Only countdown controls need to listen to its ticks.
class OtpCountdown extends ValueNotifier<int> {
  OtpCountdown() : super(0);

  Timer? _timer;

  void start(int seconds) {
    stop();
    value = seconds;
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      value--;
      if (value == 0) stop();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
