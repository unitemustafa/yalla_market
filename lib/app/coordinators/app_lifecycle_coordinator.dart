import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/offers/presentation/cubit/offer_catalog_cubit.dart';
import '../../features/store/presentation/cubit/order_history_cubit.dart';

class ResumeRefreshGuard {
  bool _inFlight = false;

  Future<void> run({
    required Future<bool> Function() validateSession,
    required Future<void> Function() refreshHome,
    Future<void> Function()? refreshOrders,
    Future<void> Function()? refreshOffers,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      if (await validateSession()) {
        await Future.wait([
          refreshHome(),
          if (refreshOrders != null) refreshOrders(),
          if (refreshOffers != null) refreshOffers(),
        ]);
      }
    } finally {
      _inFlight = false;
    }
  }
}

class AppLifecycleCoordinator {
  final ResumeRefreshGuard _refreshGuard = ResumeRefreshGuard();
  bool _wasBackgrounded = false;

  void handleState(
    AppLifecycleState state, {
    required BuildContext context,
    required bool Function() isMounted,
  }) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      unawaited(_refreshAfterResume(context, isMounted));
    }
  }

  Future<void> _refreshAfterResume(
    BuildContext context,
    bool Function() isMounted,
  ) async {
    if (!isMounted()) return;
    final authCubit = context.read<AuthCubit>();
    if (authCubit.state is! AuthAuthenticated) return;
    try {
      await _refreshGuard.run(
        validateSession: () async {
          final sessionIsValid = await authCubit.validateSession();
          return isMounted() &&
              sessionIsValid &&
              authCubit.state is AuthAuthenticated;
        },
        refreshHome: () => context.read<HomeCubit>().loadHome(force: true),
        refreshOrders: () =>
            context.read<OrderHistoryCubit>().loadOrders(force: true),
        refreshOffers: () =>
            context.read<OfferCatalogCubit>().loadOffers(force: true),
      );
    } catch (_) {
      // A background refresh failure must not invalidate a valid session.
    }
  }
}
