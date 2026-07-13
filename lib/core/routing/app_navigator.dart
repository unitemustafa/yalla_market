import 'package:flutter/material.dart';

import 'app_routes.dart';

abstract final class AppNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void goToLogin() {
    key.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  static void goToAccountDisabled() {
    key.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.accountDisabled,
      (route) => false,
    );
  }
}
