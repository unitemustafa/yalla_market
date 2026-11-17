import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A card-to-page transition that leaves nested card actions independent.
class AppOpenContainer extends StatefulWidget {
  const AppOpenContainer({
    super.key,
    required this.routeSettings,
    required this.openBuilder,
    required this.closedBuilder,
    this.closedColor,
    this.beforeOpen,
  });

  final RouteSettings routeSettings;
  final WidgetBuilder openBuilder;
  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;
  final Color? closedColor;
  final VoidCallback? beforeOpen;

  @override
  State<AppOpenContainer> createState() => _AppOpenContainerState();
}

class _AppOpenContainerState extends State<AppOpenContainer> {
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    // OpenContainer retains this callback for the lifetime of its route. Capture
    // this build's destination so source refreshes cannot retarget an open page.
    final destinationBuilder = widget.openBuilder;
    // OpenContainer routes do not provide the native iOS back gesture.
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return widget.closedBuilder(context, () async {
        if (_opening) return;
        _opening = true;
        try {
          widget.beforeOpen?.call();
          await Navigator.of(context).push<void>(
            CupertinoPageRoute<void>(
              settings: widget.routeSettings,
              builder: destinationBuilder,
            ),
          );
        } finally {
          _opening = false;
        }
      });
    }
    return OpenContainer<void>(
      tappable: false,
      routeSettings: widget.routeSettings,
      transitionType: ContainerTransitionType.fade,
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 350),
      closedElevation: 0,
      openElevation: 0,
      closedColor: widget.closedColor ?? Theme.of(context).colorScheme.surface,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      openBuilder: (context, _) => destinationBuilder(context),
      closedBuilder: (context, open) => widget.closedBuilder(context, () {
        if (_opening) return;
        _opening = true;
        widget.beforeOpen?.call();
        open();
      }),
      onClosed: (_) => _opening = false,
    );
  }
}
