import 'package:flutter/foundation.dart';

class SessionExpiredNotifier extends ChangeNotifier {
  SessionExpiredNotifier();

  static final SessionExpiredNotifier instance = SessionExpiredNotifier();

  void notifyExpired() {
    notifyListeners();
  }
}
