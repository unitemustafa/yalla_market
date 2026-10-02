import 'package:flutter/material.dart';

/// Shares the navigator's existing observer with media surfaces.
class MediaRouteObserverScope extends InheritedWidget {
  const MediaRouteObserverScope({
    super.key,
    required this.observer,
    required super.child,
  });
  final RouteObserver<ModalRoute<dynamic>> observer;

  static RouteObserver<ModalRoute<dynamic>>? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MediaRouteObserverScope>()
          ?.observer;

  @override
  bool updateShouldNotify(MediaRouteObserverScope oldWidget) =>
      !identical(observer, oldWidget.observer);
}
