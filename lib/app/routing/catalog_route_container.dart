import 'package:flutter/material.dart';

import '../../core/presentation/widgets/app_open_container.dart';
import 'app_router.dart';

/// Uses the same guarded destination and wrappers as named catalog routes.
class CatalogRouteContainer extends StatelessWidget {
  const CatalogRouteContainer({
    super.key,
    required this.settings,
    required this.closedBuilder,
    this.closedColor,
    this.beforeOpen,
  });

  final RouteSettings settings;
  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;
  final Color? closedColor;
  final VoidCallback? beforeOpen;

  @override
  Widget build(BuildContext context) => AppOpenContainer(
    routeSettings: settings,
    openBuilder: (context) => AppRouter.buildContainerPage(context, settings),
    closedBuilder: closedBuilder,
    closedColor: closedColor,
    beforeOpen: beforeOpen,
  );
}
