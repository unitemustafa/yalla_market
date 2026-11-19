import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Opens a card with a native page transition and independent nested actions.
class AppOpenContainer extends StatefulWidget {
  const AppOpenContainer({
    super.key,
    required this.routeSettings,
    required this.openBuilder,
    required this.closedBuilder,
    this.closedColor,
    this.beforeOpen,
    this.androidRouteBuilder,
  });

  final RouteSettings routeSettings;
  final WidgetBuilder openBuilder;
  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;
  final Color? closedColor;
  final VoidCallback? beforeOpen;
  final Route<void> Function(WidgetBuilder builder)? androidRouteBuilder;

  @override
  State<AppOpenContainer> createState() => _AppOpenContainerState();
}

class _AppOpenContainerState extends State<AppOpenContainer> {
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    // Capture the destination so source refreshes cannot retarget an open page.
    final destinationBuilder = widget.openBuilder;
    // Keep page construction lazy and independent of transition frames. Native
    // routes can animate snapshots instead of scaling/clipping a live page.
    final destination = RepaintBoundary(
      child: Builder(builder: destinationBuilder),
    );
    final platform = Theme.of(context).platform;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: widget.closedColor ?? Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: widget.closedBuilder(context, () async {
        if (_opening) return;
        _opening = true;
        try {
          widget.beforeOpen?.call();
          final Route<void> route;
          if (disableAnimations) {
            route = PageRouteBuilder<void>(
              settings: widget.routeSettings,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (_, _, _) => destination,
            );
          } else if (platform == TargetPlatform.iOS) {
            route = CupertinoPageRoute<void>(
              settings: widget.routeSettings,
              builder: (_) => destination,
            );
          } else if (platform == TargetPlatform.android &&
              widget.androidRouteBuilder != null) {
            route = widget.androidRouteBuilder!((_) => destination);
          } else {
            route = MaterialPageRoute<void>(
              settings: widget.routeSettings,
              builder: (_) => destination,
            );
          }
          await Navigator.of(context).push<void>(route);
        } finally {
          _opening = false;
        }
      }),
    );
  }
}
