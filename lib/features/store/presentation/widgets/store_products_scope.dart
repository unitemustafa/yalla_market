import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../core/presentation/widgets/refresh_on_return.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../location/presentation/cubit/location_cubit.dart';
import '../../../location/domain/entities/city_data.dart';
import '../../domain/entities/store_product_page.dart';
import '../cubit/store_products_cubit.dart';

/// Owns one route's product feed, and observes account/region changes.
class StoreProductsScope extends StatefulWidget {
  const StoreProductsScope({
    super.key,
    required this.marketId,
    required this.scrollController,
    required this.builder,
    this.query = '',
    this.subcategoryId,
    this.sort = StoreProductSort.name,
  });
  final String marketId;
  final String query;
  final String? subcategoryId;
  final StoreProductSort sort;
  final ScrollController scrollController;
  final Widget Function(BuildContext, StoreProductsCubit) builder;
  @override
  State<StoreProductsScope> createState() => _StoreProductsScopeState();
}

class _StoreProductsScopeState extends State<StoreProductsScope> {
  late final StoreProductsCubit _cubit;
  StreamSubscription<StoreProductsState>? _subscription;
  String _scopeKey = '';
  bool _checkQueued = false;
  @override
  void initState() {
    super.initState();
    _cubit = createStoreProductsCubit();
    widget.scrollController.addListener(_checkViewport);
    _subscription = _cubit.stream.listen((_) => _queueCheck());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthCubit?>()?.state;
    final city = context.watch<LocationCubit?>()?.state.selectedCity;
    final user = auth is AuthAuthenticated
        ? auth.session.user.id
        : auth.runtimeType;
    _scopeKey =
        '$user|${city?.slug}|${city?.serviceCityId}|${city?.source == RegionSource.general}';
    _configure();
    _queueCheck();
  }

  @override
  void didUpdateWidget(StoreProductsScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.scrollController, widget.scrollController)) {
      oldWidget.scrollController.removeListener(_checkViewport);
      widget.scrollController.addListener(_checkViewport);
    }
    _configure();
    _queueCheck();
  }

  void _configure() => unawaited(
    _cubit.configure(
      marketId: widget.marketId,
      query: widget.query,
      subcategoryId: widget.subcategoryId,
      sort: widget.sort,
      scopeKey: _scopeKey,
    ),
  );

  void _queueCheck() {
    if (_checkQueued || !mounted) return;
    _checkQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkQueued = false;
      if (mounted) _checkViewport();
    });
  }

  void _checkViewport() {
    if (!mounted ||
        !widget.scrollController.hasClients ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final state = _cubit.state;
    final position = widget.scrollController.position;
    if (state.error == null &&
        state.moreError == null &&
        state.hasMore &&
        !state.isLoading &&
        !state.loadingMore &&
        position.extentAfter <= position.viewportDimension * 2) {
      unawaited(_cubit.loadMore());
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_checkViewport);
    unawaited(_subscription?.cancel());
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RefreshOnReturn(
    refreshOnMount: false,
    onRefresh: _cubit.refreshIfStale,
    onInvalidated: () => _cubit.refreshIfStale(invalidated: true),
    child: BlocProvider.value(
      value: _cubit,
      child: Builder(builder: (context) => widget.builder(context, _cubit)),
    ),
  );
}
