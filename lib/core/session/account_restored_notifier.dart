import 'package:flutter/foundation.dart';

class AccountRestoredNotifier extends ValueNotifier<bool> {
  AccountRestoredNotifier() : super(false);

  static final AccountRestoredNotifier instance = AccountRestoredNotifier();

  void markRestored() => value = true;

  void reset() => value = false;
}
