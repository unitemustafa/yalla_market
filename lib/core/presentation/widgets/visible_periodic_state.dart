import 'dart:async';
import 'package:flutter/widgets.dart';

/// Lifecycle-aware clock for small countdown widgets. Timers must be stopped
/// synchronously on pause: background apps do not render dependency updates.
abstract class VisiblePeriodicState<W extends StatefulWidget> extends State<W>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime currentTime = DateTime.now();
  bool _tickerEnabled = true;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  void _syncClock() {
    _timer?.cancel();
    currentTime = DateTime.now();
    if (_tickerEnabled && _foreground) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => currentTime = DateTime.now());
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _syncClock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncClock();
    if (_foreground && mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
