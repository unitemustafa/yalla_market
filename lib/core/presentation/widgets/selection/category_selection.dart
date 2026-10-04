import 'package:flutter/material.dart';

/// Category filters keep keyboard focus feedback without a pressed ink halo.
class CategorySelectionTap extends StatelessWidget {
  const CategorySelectionTap({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
  });

  final VoidCallback onTap;
  final Widget child;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: borderRadius,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    child: child,
  );
}

/// Only the results animate; category controls retain their state and position.
class CategoryContentTransition extends StatelessWidget {
  const CategoryContentTransition({
    super.key,
    required this.selectionKey,
    required this.child,
  });

  final Object selectionKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      reverseDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, 6 * (1 - animation.value)),
            child: child,
          ),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [
          ...previous.map(
            (child) => PositionedDirectional(
              top: 0,
              start: 0,
              end: 0,
              child: ExcludeSemantics(child: IgnorePointer(child: child)),
            ),
          ),
          ?current,
        ],
      ),
      child: KeyedSubtree(key: ValueKey(selectionKey), child: child),
    ),
  );
}
