import 'package:flutter/foundation.dart';

class AccountInactiveNotifier extends ChangeNotifier {
  AccountInactiveNotifier();

  static final AccountInactiveNotifier instance = AccountInactiveNotifier();

  bool _isInactive = false;
  Future<void>? _inactivationFuture;
  bool get isInactive => _isInactive;

  Future<void> inactivateAfter(Future<void> Function() clearSession) async {
    if (_isInactive) return;
    final pending = _inactivationFuture;
    if (pending != null) return pending;

    final operation = () async {
      await clearSession();
      notifyInactive();
    }();
    _inactivationFuture = operation;
    try {
      await operation;
    } finally {
      if (identical(_inactivationFuture, operation)) {
        _inactivationFuture = null;
      }
    }
  }

  void notifyInactive() {
    if (_isInactive) return;
    _isInactive = true;
    notifyListeners();
  }

  void reset() {
    _isInactive = false;
  }
}
