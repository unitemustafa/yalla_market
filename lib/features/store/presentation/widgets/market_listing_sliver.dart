import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../app/routing/app_route_arguments.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/presentation/cubit/paged_list_cubit.dart';
import '../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../core/presentation/widgets/refresh_on_return.dart';
import '../../../../core/presentation/widgets/search/app_search_actions_bar.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../core/presentation/widgets/states/app_skeleton.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../location/presentation/cubit/location_cubit.dart';
import '../../domain/entities/store_data.dart';
import '../../domain/usecases/get_market_listing_usecase.dart';
import '../cubit/market_listing_cubit.dart';
import '../views/brand/market_type_rail.dart';
import 'store_market_card.dart';

class MarketListingSliver extends StatefulWidget {
  const MarketListingSliver({
    super.key,
    required this.title,
    required this.controller,
    this.classificationId = '',
    this.popular = false,
    this.latest = false,
    this.onReady,
  });
  final String title;
  final String classificationId;
  final ScrollController controller;
  final bool popular;
  final bool latest;
  final ValueChanged<MarketListingCubit>? onReady;
  @override
  State<MarketListingSliver> createState() => _MarketListingSliverState();
}

class _MarketListingSliverState extends State<MarketListingSliver> {
  late final MarketListingCubit _cubit = sl<MarketListingCubit>();
  final _search = TextEditingController();
  Timer? _debounce;
  StreamSubscription<PagedListState<StoreMarketData>>? _subscription;
  String _query = '';
  String? _type;
  String _scope = '';
  bool _queued = false;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_check);
    _subscription = _cubit.stream.listen((_) => _queueCheck());
    widget.onReady?.call(_cubit);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthCubit?>()?.state;
    final city = context.watch<LocationCubit?>()?.state.selectedCity;
    final scope =
        '${auth is AuthAuthenticated ? auth.session.user.id : auth.runtimeType}|${city?.slug}|${city?.serviceCityId}';
    if (_scope != scope) {
      _scope = scope;
      _configure();
    }
  }

  @override
  void didUpdateWidget(MarketListingSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_check);
      widget.controller.addListener(_check);
    }
    if (oldWidget.classificationId != widget.classificationId ||
        oldWidget.popular != widget.popular ||
        oldWidget.latest != widget.latest) {
      _type = null;
      _query = '';
      _search.clear();
      _configure();
    }
    widget.onReady?.call(_cubit);
  }

  void _configure() => unawaited(
    _cubit.configure((
      classificationId: widget.classificationId,
      query: _query,
      typeId: _type,
      popular: widget.popular,
      latest: widget.latest,
      scope: _scope,
    )),
  );
  void _queueCheck() {
    if (_queued || !mounted) {
      return;
    }
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _queued = false;
      if (mounted) _check();
    });
  }

  void _check() {
    if (!mounted ||
        !widget.controller.hasClients ||
        ModalRoute.of(context)?.isCurrent == false ||
        _cubit.state.moreError != null ||
        _cubit.state.error != null) {
      return;
    }
    if (widget.controller.position.extentAfter <
        widget.controller.position.viewportDimension) {
      unawaited(_cubit.loadMore());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_check);
    _debounce?.cancel();
    _search.dispose();
    unawaited(_subscription?.cancel());
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RefreshOnReturn(
    refreshOnMount: false,
    onRefresh: _cubit.refreshIfStale,
    onInvalidated: _cubit.refresh,
    child: BlocBuilder<MarketListingCubit, PagedListState<StoreMarketData>>(
      bloc: _cubit,
      builder: (context, state) {
        final page = state.page is MarketListingPage
            ? state.page as MarketListingPage
            : null;
        final prefix = widget.classificationId.isNotEmpty
            ? 'classification_store'
            : widget.popular
            ? 'popular_stores_page'
            : 'latest_stores_page';
        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageTopBar(
                    titleMaxLines: null,
                    title: widget.title,
                    subtitle: widget.classificationId.isNotEmpty
                        ? '${page?.totalCount ?? 0} stores'
                        : widget.popular
                        ? 'Browse all popular stores'
                        : 'Browse the newest stores',
                  ),
                  const AppRefreshAnchor(),
                  const SizedBox(height: 18),
                  if (widget.classificationId.isNotEmpty) ...[
                    AppSearchField(
                      key: const ValueKey('category_store_search_field'),
                      hintText: 'Search stores...',
                      controller: _search,
                      onChanged: (value) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 350),
                          () {
                            if (!mounted || _query == value.trim()) {
                              return;
                            }
                            _query = value.trim();
                            _configure();
                          },
                        );
                      },
                    ),
                    if (page?.types.isNotEmpty == true) ...[
                      const SizedBox(height: 20),
                      MarketTypeRail(
                        types: page!.types,
                        selectedId: _type ?? page.selectedTypeId,
                        onSelected: (id) {
                          _type = id;
                          _configure();
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
            if (state.loading && state.items.isEmpty)
              const SliverToBoxAdapter(child: AppSkeletonList(rowHeight: 150))
            else if (state.error != null && state.items.isEmpty)
              SliverToBoxAdapter(
                child: AppErrorState(
                  title: 'Store could not load',
                  message: state.error!,
                  onRetry: _cubit.refresh,
                ),
              )
            else if (state.items.isEmpty)
              const SliverToBoxAdapter(
                child: AppEmptyState(
                  title: 'No stores available',
                  message: 'Try a different store name.',
                ),
              )
            else
              SliverList.builder(
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final market = state.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StoreMarketCard(
                      key: ValueKey('${prefix}_${market.id}'),
                      market: market,
                      keyPrefix: prefix,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.brandProducts,
                        arguments: BrandProductsRouteArgs(
                          brand: market.name,
                          logo: market.image,
                          productCount: market.productCountLabel,
                          classificationId: market.classificationId,
                          marketId: market.id,
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (state.hasMore || state.moreError != null || state.error != null)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    if (state.moreError != null)
                      Text(context.tr(state.moreError!)),
                    TextButton(
                      onPressed: state.loadingMore
                          ? null
                          : state.error != null
                          ? _cubit.refresh
                          : _cubit.loadMore,
                      child: state.loadingMore
                          ? const CircularProgressIndicator()
                          : Text(
                              context.tr(
                                state.moreError == null
                                    ? 'Load more'
                                    : 'Try again',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
}
