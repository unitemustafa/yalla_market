import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

enum _RefreshPhase { idle, dragging, armed, refreshing, returning }

/// Pull-to-refresh without a floating disc. Place an [AppRefreshAnchor]
/// between the page's header and its refreshable content.
class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  static const ScrollPhysics scrollPhysics = AlwaysScrollableScrollPhysics(
    parent: _AppRefreshScrollPhysics(parent: ClampingScrollPhysics()),
  );

  final RefreshCallback onRefresh;
  final Widget child;
  final ScrollNotificationPredicate notificationPredicate;

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator>
    with TickerProviderStateMixin {
  static const _triggerDistance = 140.0;
  static const _restingExtent = 56.0;
  late final AnimationController _extent;
  late final AnimationController _rotation;
  _RefreshPhase _phase = _RefreshPhase.idle;
  double _dragDistance = 0;
  bool _eligibleDrag = false;
  bool _reduceMotion = false;
  bool _tickerEnabled = true;
  int? _activePointer;
  bool _dragCanceled = false;

  @override
  void initState() {
    super.initState();
    _extent = AnimationController.unbounded(vsync: this);
    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _updateRotation();
  }

  void _updateRotation() {
    if (_phase == _RefreshPhase.refreshing &&
        !_reduceMotion &&
        _tickerEnabled) {
      if (!_rotation.isAnimating) _rotation.repeat();
    } else {
      _rotation.stop();
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification) ||
        notification.metrics.axisDirection != AxisDirection.down) {
      return false;
    }
    if (_phase == _RefreshPhase.refreshing ||
        _phase == _RefreshPhase.returning) {
      return false;
    }
    switch (notification) {
      case ScrollStartNotification(:final dragDetails):
        _eligibleDrag =
            dragDetails != null && notification.metrics.extentBefore == 0;
        _dragDistance = 0;
      case OverscrollNotification(:final overscroll, :final dragDetails):
        if (_eligibleDrag &&
            dragDetails != null &&
            overscroll < 0 &&
            notification.metrics.extentBefore == 0) {
          _setDragDistance(_dragDistance - overscroll);
        }
      case ScrollUpdateNotification(:final scrollDelta, :final dragDetails):
        if (_eligibleDrag &&
            dragDetails != null &&
            scrollDelta != null &&
            scrollDelta > 0 &&
            _dragDistance > 0) {
          _setDragDistance(_dragDistance - scrollDelta);
        }
      case ScrollEndNotification():
        _eligibleDrag = false;
        // PointerCancel is delivered to ancestor listeners after the
        // scrollable ends its drag. Decide only after that event dispatch.
        scheduleMicrotask(() {
          if (!mounted) return;
          if (_phase == _RefreshPhase.armed && !_dragCanceled) {
            unawaited(_refresh());
          } else if (_phase == _RefreshPhase.dragging ||
              _phase == _RefreshPhase.armed) {
            unawaited(_returnToIdle());
          }
        });
      default:
        break;
    }
    return false;
  }

  void _setDragDistance(double distance) {
    _dragDistance = distance.clamp(0, 350);
    _phase = _dragDistance >= _triggerDistance
        ? _RefreshPhase.armed
        : _RefreshPhase.dragging;
    // Linear resistance up to the trigger, then a progressively softer pull.
    _extent.value = _dragDistance <= _triggerDistance
        ? _dragDistance * 0.4
        : _restingExtent +
              32 * (1 - math.exp(-(_dragDistance - _triggerDistance) / 100));
    _rotation.value = (_dragDistance / _triggerDistance) % 1;
  }

  Future<void> _animateExtent(double value, int milliseconds) async {
    if (_reduceMotion || !_tickerEnabled) {
      _extent.value = value;
      return;
    }
    await _extent
        .animateTo(
          value,
          duration: Duration(milliseconds: milliseconds),
          curve: Curves.easeOutCubic,
        )
        .orCancel;
  }

  Future<void> _refresh() async {
    _phase = _RefreshPhase.refreshing;
    _updateRotation();
    try {
      // Start I/O immediately, while the indicator settles into place.
      await Future.wait<void>([
        Future<void>.sync(widget.onRefresh),
        _animateExtent(_restingExtent, 200),
      ]);
    } on TickerCanceled {
      // The route was disposed while the settling animation was running.
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'yalla_market',
          context: ErrorDescription('while refreshing page content'),
        ),
      );
    } finally {
      if (mounted) await _returnToIdle();
    }
  }

  Future<void> _returnToIdle() async {
    _phase = _RefreshPhase.returning;
    _rotation.stop();
    try {
      await _animateExtent(0, 240);
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    _dragDistance = 0;
    _phase = _RefreshPhase.idle;
  }

  @override
  void dispose() {
    _extent.dispose();
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _RefreshScope(
      state: this,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 && notification.leading) {
            notification.disallowIndicator();
          }
          return false;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: Listener(
            onPointerDown: (event) {
              if (_activePointer != null) return;
              _activePointer = event.pointer;
              _dragCanceled = false;
            },
            onPointerUp: (event) {
              if (_activePointer == event.pointer) _activePointer = null;
            },
            onPointerCancel: (event) {
              if (_activePointer != event.pointer) return;
              _activePointer = null;
              _dragCanceled = true;
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Consume reverse movement while the refresh gap is open, before Flutter
/// updates ScrollPosition. Otherwise a reversing finger scrolls the header.
class _AppRefreshScrollPhysics extends ScrollPhysics {
  const _AppRefreshScrollPhysics({super.parent});

  @override
  _AppRefreshScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      _AppRefreshScrollPhysics(parent: buildParent(ancestor));

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    final state = position is ScrollPosition
        ? position.context.notificationContext
              ?.getInheritedWidgetOfExactType<_RefreshScope>()
              ?.state
        : null;
    if (state != null &&
        state._eligibleDrag &&
        offset < 0 &&
        state._dragDistance > 0 &&
        (state._phase == _RefreshPhase.dragging ||
            state._phase == _RefreshPhase.armed)) {
      state._setDragDistance(state._dragDistance + offset);
      return 0;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }
}

class _RefreshScope extends InheritedWidget {
  const _RefreshScope({required this.state, required super.child});

  final _AppRefreshIndicatorState state;

  @override
  bool updateShouldNotify(_RefreshScope oldWidget) => state != oldWidget.state;
}

/// Reveals the spinner in the content flow, leaving preceding headers still.
/// For slivers use `SliverToBoxAdapter(child: AppRefreshAnchor())`.
class AppRefreshAnchor extends StatelessWidget {
  const AppRefreshAnchor({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context
        .dependOnInheritedWidgetOfExactType<_RefreshScope>()
        ?.state;
    if (state == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: state._extent,
      builder: (context, _) {
        final extent = state._extent.value;
        if (extent <= 0) return const SizedBox.shrink();
        return Semantics(
          label: MaterialLocalizations.of(
            context,
          ).refreshIndicatorSemanticLabel,
          liveRegion: true,
          child: SizedBox(
            height: extent,
            width: double.infinity,
            child: ClipRect(
              child: Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CustomPaint(
                    painter: _RefreshArcPainter(
                      rotation: state._rotation,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RefreshArcPainter extends CustomPainter {
  _RefreshArcPainter({required this.rotation, required this.color})
    : super(repaint: rotation);

  final Animation<double> rotation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rect = (Offset.zero & size).deflate(2);
    final angle = rotation.value * math.pi * 2;
    final sweep = (50 + 15 * math.sin(angle)) * math.pi / 180;
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(rect, angle + i * math.pi * 2 / 3, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RefreshArcPainter oldDelegate) =>
      color != oldDelegate.color || rotation != oldDelegate.rotation;
}
