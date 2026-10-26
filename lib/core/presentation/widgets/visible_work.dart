import 'package:flutter/widgets.dart';
import '../media/media_route_observer_scope.dart';

/// Pauses optional visual work while a tab/route/app is not visible.
class VisibleWork extends StatefulWidget {
  const VisibleWork({
    super.key,
    required this.builder,
    this.onVisibilityChanged,
  });
  final Widget Function(BuildContext, bool visible) builder;
  final ValueChanged<bool>? onVisibilityChanged;
  @override
  State<VisibleWork> createState() => _VisibleWorkState();
}

class _VisibleWorkState extends State<VisibleWork>
    with WidgetsBindingObserver, RouteAware {
  RouteObserver<ModalRoute<dynamic>>? _observer;
  ModalRoute<dynamic>? _route;
  bool _covered = false;
  bool _foreground = true;
  bool _tickerEnabled = true;
  bool get _visible => _foreground && !_covered && _tickerEnabled;
  void _notify() => widget.onVisibilityChanged?.call(_visible);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    final observer = MediaRouteObserverScope.maybeOf(context);
    final route = ModalRoute.of(context);
    if (observer != _observer || route != _route) {
      _observer?.unsubscribe(this);
      _observer = observer;
      _route = route;
      if (observer != null && route != null) observer.subscribe(this, route);
      _covered = route?.isCurrent == false;
    }
    _notify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _notify();
    setState(() {});
  }

  @override
  void didPushNext() {
    _covered = true;
    _notify();
    setState(() {});
  }

  @override
  void didPopNext() {
    _covered = false;
    _notify();
    setState(() {});
  }

  @override
  void dispose() {
    _observer?.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _foreground && !_covered && TickerMode.valuesOf(context).enabled;
    return TickerMode(
      enabled: visible,
      child: widget.builder(context, visible),
    );
  }
}
