import 'package:flutter/material.dart';

/// Own this alongside the page state so list remounts cannot replay entrance.
class AppListEntranceController {
  AppListEntranceController({required TickerProvider vsync})
    : _animation = AnimationController(vsync: vsync);

  static const _itemDuration = 300;
  static const _stagger = 50;
  static const _maxItems = 6;

  final AnimationController _animation;
  final Map<Object, int> _slots = {};
  bool _prepared = false;
  bool _skip = false;
  bool _disposed = false;
  int _duration = _itemDuration;

  /// Capture only the first nonempty data set. Updates keep their original slots.
  void prepare(Iterable<Object> ids, {required bool disableAnimations}) {
    if (disableAnimations) {
      _skip = true;
      if (_animation.isAnimating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) _animation.stop();
        });
      }
    }
    if (_prepared) return;
    final initialIds = ids.take(_maxItems).toList(growable: false);
    if (initialIds.isEmpty) return;

    _prepared = true;
    for (var index = 0; index < initialIds.length; index++) {
      _slots[initialIds[index]] = index;
    }
    _duration = _itemDuration + (initialIds.length - 1) * _stagger;
    _animation.duration = Duration(milliseconds: _duration);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && !_skip) _animation.forward();
    });
  }

  double _progress(Object id) {
    final slot = _slots[id];
    if (_skip || slot == null) return 1;
    final elapsed = _animation.value * _duration;
    final progress = ((elapsed - slot * _stagger) / _itemDuration).clamp(
      0.0,
      1.0,
    );
    return Curves.easeOutCubic.transform(progress);
  }

  void dispose() {
    _disposed = true;
    _animation.dispose();
  }
}

/// Animates paint only; list layout and the child's identity stay stable.
class AppListEntranceItem extends StatelessWidget {
  const AppListEntranceItem({
    super.key,
    required this.controller,
    required this.itemId,
    required this.child,
  });

  final AppListEntranceController controller;
  final Object itemId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: controller._animation,
      child: child,
      builder: (context, child) {
        final progress = disableAnimations ? 1.0 : controller._progress(itemId);
        return IgnorePointer(
          ignoring: progress == 0,
          child: Opacity(
            opacity: progress,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - progress)),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
