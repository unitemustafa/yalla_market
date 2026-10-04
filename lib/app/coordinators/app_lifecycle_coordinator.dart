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
      final syncTimes = [
        context.read<HomeCubit>().lastNetworkSuccessAt,
        context.read<ProductCatalogCubit>().lastNetworkSuccessAt,
        context.read<ProductDiscoveryCubit>().lastNetworkSuccessAt,
        context.read<StoreCubit>().lastNetworkSuccessAt,
        context.read<OrderHistoryCubit>().lastNetworkSuccessAt,
        context.read<OfferCatalogCubit>().lastNetworkSuccessAt,
      ];
      final now = _now().toUtc();
      if (syncTimes.any(
        (time) =>
            time == null ||
            now.isBefore(time) ||
            now.difference(time) >= minimumBackgroundDuration,
      )) {
        unawaited(refreshNow(context, isMounted, onlyStale: true));
      }
    }
  }

  Future<void> refreshNow(
    BuildContext context,
    bool Function() isMounted, {
    bool onlyStale = false,
  }) async {
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
        refreshHome: () => onlyStale
            ? context.read<HomeCubit>().refreshIfStale()
            : context.read<HomeCubit>().refreshSilently(),
        refreshProducts: () => onlyStale
            ? context.read<ProductCatalogCubit>().refreshIfStale()
            : context.read<ProductCatalogCubit>().refreshSilently(),
        refreshDiscovery: () => onlyStale
            ? context.read<ProductDiscoveryCubit>().refreshIfStale()
            : context.read<ProductDiscoveryCubit>().refreshSilently(),
        refreshStore: () => onlyStale
            ? context.read<StoreCubit>().refreshIfStale()
            : context.read<StoreCubit>().refreshSilently(),
        refreshOrders: () => onlyStale
            ? context.read<OrderHistoryCubit>().refreshIfStale()
            : context.read<OrderHistoryCubit>().loadOrders(force: true),
        refreshOffers: () => onlyStale
            ? context.read<OfferCatalogCubit>().refreshIfStale()
            : context.read<OfferCatalogCubit>().loadOffers(force: true),
      );
    } catch (_) {
      // A background refresh failure must not invalidate a valid session.
    }
  }
}
