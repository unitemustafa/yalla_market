import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Adds press feedback to a Material button without changing its gestures.
///
/// The button returned by [builder] must use the supplied states controller.
class AppButtonFeedback extends StatefulWidget {
  const AppButtonFeedback({super.key, required this.builder});

  final Widget Function(BuildContext context, WidgetStatesController states)
  builder;

  @override
  State<AppButtonFeedback> createState() => _AppButtonFeedbackState();
}

class _AppButtonFeedbackState extends State<AppButtonFeedback>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 100);
  final _states = WidgetStatesController();
  late final AnimationController _animation;
  bool _pressed = false;
  bool _disableAnimations = false;
  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(vsync: this, duration: _duration);
    _states.addListener(_handleStatesChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (_disableAnimations) _animation.value = 0;
  }

  void _handleStatesChanged() {
    // Material buttons can update their states while rebuilding (e.g. loading).
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_updateScheduled) return;
      _updateScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _updateScheduled = false;
        if (mounted) _updatePress();
      });
      return;
    }
    _updatePress();
  }

  void _updatePress() {
    final pressed =
        _states.value.contains(WidgetState.pressed) &&
        !_states.value.contains(WidgetState.disabled);
    if (pressed == _pressed) return;
    _pressed = pressed;
    if (pressed) unawaited(_lightImpact());
    _animation.animateTo(
      pressed && !_disableAnimations ? 1 : 0,
      duration: _disableAnimations ? Duration.zero : _duration,
      curve: Curves.easeOut,
    );
  }

  Future<void> _lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } on PlatformException {
      // Feedback availability must not prevent the button's action.
    } on MissingPluginException {
      // Some hosts do not provide native haptic feedback.
    }
  }

  @override
  void dispose() {
    _states.removeListener(_handleStatesChanged);
    _states.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Transform.scale(
        scale: _disableAnimations ? 1 : 1 - 0.04 * _animation.value,
        transformHitTests: false,
        child: child,
      ),
      child: widget.builder(context, _states),
    );
  }
}
