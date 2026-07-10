import 'package:flutter/foundation.dart';

class AccountInactiveNotifier extends ChangeNotifier {
  AccountInactiveNotifier();

  static final AccountInactiveNotifier instance = AccountInactiveNotifier();

  bool _isInactive = false;

  bool get isInactive => _isInactive;

  void notifyInactive() {
    if (_isInactive) return;
    _isInactive = true;
    notifyListeners();
  }

  void reset() {
    _isInactive = false;
  }
}
