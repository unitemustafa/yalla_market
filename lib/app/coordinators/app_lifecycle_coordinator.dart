import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/offers/presentation/cubit/offer_catalog_cubit.dart';
import '../../features/store/presentation/cubit/order_history_cubit.dart';
import '../../features/store/presentation/cubit/product_catalog_cubit.dart';
import '../../features/store/presentation/cubit/product_discovery_cubit.dart';
import '../../features/store/presentation/cubit/store_cubit.dart';

class ResumeRefreshGuard {
  bool _inFlight = false;

  Future<void> run({
    required Future<bool> Function() validateSession,
    required Future<void> Function() refreshHome,
    Future<void> Function()? refreshProducts,
    Future<void> Function()? refreshDiscovery,
    Future<void> Function()? refreshStore,
    Future<void> Function()? refreshOrders,
    Future<void> Function()? refreshOffers,
  }) async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      if (await validateSession()) {
        await Future.wait([
          refreshHome(),
          if (refreshProducts != null) refreshProducts(),
          if (refreshDiscovery != null) refreshDiscovery(),
          if (refreshStore != null) refreshStore(),
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
  AppLifecycleCoordinator({
    DateTime Function()? now,
    this.minimumBackgroundDuration = const Duration(seconds: 60),
  }) : _now = now ?? DateTime.now;

  final ResumeRefreshGuard _refreshGuard = ResumeRefreshGuard();
  final DateTime Function() _now;
  final Duration minimumBackgroundDuration;
  bool _wasBackgrounded = false;

  void handleState(
    AppLifecycleState state, {
    required BuildContext context,
    required bool Function() isMounted,
  }) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      final lastSuccessfulSync = context.read<HomeCubit>().lastNetworkSuccessAt;
      if (lastSuccessfulSync == null ||
          _now().toUtc().difference(lastSuccessfulSync.toUtc()) >=
              minimumBackgroundDuration) {
        unawaited(refreshNow(context, isMounted));
      }
    }
  }

  Future<void> refreshNow(
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
        refreshHome: () => context.read<HomeCubit>().refreshSilently(),
        refreshProducts: () =>
            context.read<ProductCatalogCubit>().refreshSilently(),
        refreshDiscovery: () =>
            context.read<ProductDiscoveryCubit>().refreshSilently(),
        refreshStore: () => context.read<StoreCubit>().refreshSilently(),
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
