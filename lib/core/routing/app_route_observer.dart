import 'package:flutter/material.dart';

class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver(this.onRouteChanged);

  final VoidCallback onRouteChanged;
  String? currentRouteName;

  void _update(Route<dynamic>? route) {
    currentRouteName = route?.settings.name;
    onRouteChanged();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _update(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _update(previousRoute);
  }
}
