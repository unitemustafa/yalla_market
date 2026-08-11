import 'package:flutter/material.dart';

import 'app/app_coordinator.dart';
import 'app/app_providers.dart';

export 'app/coordinators/app_lifecycle_coordinator.dart'
    show ResumeRefreshGuard;
export 'app/coordinators/app_push_event_coordinator.dart'
    show presentDeliveryAreaCreatedFeedback;

class YallaMarketApp extends StatelessWidget {
  const YallaMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppProviders(child: AppCoordinator());
  }
}
