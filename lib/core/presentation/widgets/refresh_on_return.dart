import 'dart:async';

import 'package:flutter/widgets.dart';

class PageRefreshScope extends InheritedWidget {
  const PageRefreshScope({
    super.key,
    required this.observer,
    required this.catalogChanges,
    required super.child,
  });

  final RouteObserver<PageRoute<dynamic>> observer;
  final Listenable catalogChanges;

  static PageRefreshScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageRefreshScope>();

  @override
  bool updateShouldNotify(PageRefreshScope oldWidget) =>
      observer != oldWidget.observer ||
      catalogChanges != oldWidget.catalogChanges;
}

/// Requests a freshness check when a page becomes visible again. Popup routes
/// (keyboards, dialogs, sheets) do not count as leaving and reopening a page.
class RefreshOnReturn extends StatefulWidget {
  const RefreshOnReturn({
    super.key,
    required this.onRefresh,
    required this.child,
    this.onInvalidated,
    this.refreshOnMount = true,
  });

  final Future<void> Function() onRefresh;
  final Future<void> Function()? onInvalidated;
  final bool refreshOnMount;
  final Widget child;

  @override
  State<RefreshOnReturn> createState() => _RefreshOnReturnState();
}

class _RefreshOnReturnState extends State<RefreshOnReturn>
    with RouteAware, WidgetsBindingObserver {
  PageRefreshScope? _scope;
  PageRoute<dynamic>? _route;
  bool _running = false;
  bool _scheduled = false;
  bool _pendingInvalidation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.refreshOnMount) _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = PageRefreshScope.maybeOf(context);
    final route = ModalRoute.of(context);
    final pageRoute = route is PageRoute<dynamic> ? route : null;
    if (scope == _scope && pageRoute == _route) return;
    _scope?.observer.unsubscribe(this);
    _scope?.catalogChanges.removeListener(_invalidate);
    _scope = scope;
    _route = pageRoute;
    if (pageRoute != null) scope?.observer.subscribe(this, pageRoute);
    scope?.catalogChanges.addListener(_invalidate);
  }

  void _invalidate() {
    _pendingInvalidation = true;
    if (_route?.isCurrent != true) return;
    _schedule();
  }

  @override
  void didPopNext() => _schedule();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _route?.isCurrent == true) {
      _schedule();
    }
  }

  void _schedule() {
    if (_scheduled || _running) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted && (_route == null || _route!.isCurrent)) {
        unawaited(_refresh());
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _refresh() async {
    _running = true;
    final invalidated = _pendingInvalidation;
    _pendingInvalidation = false;
    try {
      await (invalidated
          ? widget.onInvalidated ?? widget.onRefresh
          : widget.onRefresh)();
    } finally {
      _running = false;
      if (mounted && _pendingInvalidation) _schedule();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scope?.observer.unsubscribe(this);
    _scope?.catalogChanges.removeListener(_invalidate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
