import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/states/app_skeleton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../app/routing/app_route_arguments.dart';
import '../../../../app/routing/app_routes.dart';
import '../../domain/entities/store_data.dart';
import '../cubit/store_cubit.dart';
import '../cubit/store_state.dart';
import '../widgets/store_market_card.dart';

class LatestStoresView extends StatefulWidget {
  const LatestStoresView({super.key, this.showPopularStores = false});

  final bool showPopularStores;

  @override
  State<LatestStoresView> createState() => _LatestStoresViewState();
}

class _LatestStoresViewState extends State<LatestStoresView> {
  @override
  void initState() {
    super.initState();
    context.read<StoreCubit>().loadStore();
  }

  void _openStore(StoreMarketData market) {
    Navigator.pushNamed(
      context,
      AppRoutes.brandProducts,
      arguments: BrandProductsRouteArgs(
        brand: market.name,
        logo: market.image,
        productCount: market.productCountLabel,
        classificationId: market.classificationId,
        marketId: market.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AppRefreshIndicator(
          onRefresh: () => context.read<StoreCubit>().loadStore(force: true),
          child: CustomScrollView(
            physics: AppRefreshIndicator.scrollPhysics,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageTopBar(
                        title: widget.showPopularStores
                            ? 'Popular Stores'
                            : 'Latest Stores',
                        subtitle: widget.showPopularStores
                            ? 'Browse all popular stores'
                            : 'Browse the newest stores',
                      ),
                      const AppRefreshAnchor(),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                sliver: BlocBuilder<StoreCubit, StoreState>(
                  builder: (context, state) {
                    final stores =
                        (widget.showPopularStores
                            ? state.data?.popularMarkets
                            : state.data?.latestMarkets) ??
                        const <StoreMarketData>[];
                    final keyPrefix = widget.showPopularStores
                        ? 'popular_stores_page'
                        : 'latest_stores_page';
                    if ((state is StoreInitial || state is StoreLoading) &&
                        state.data == null) {
                      return const SliverToBoxAdapter(
                        child: AppSkeletonList(rowHeight: 150),
                      );
                    }
                    if (state is StoreFailure && stores.isEmpty) {
                      return SliverToBoxAdapter(
                        child: AppErrorState(
                          title: 'Store could not load',
                          message: state.message,
                          onRetry: () =>
                              context.read<StoreCubit>().loadStore(force: true),
                        ),
                      );
                    }
                    if (stores.isEmpty) {
                      return SliverToBoxAdapter(
                        child: AppEmptyState(
                          title: 'No stores available',
                          message: widget.showPopularStores
                              ? 'Popular stores will appear here once available.'
                              : 'New stores will appear here once added.',
                        ),
                      );
                    }

                    final itemCount =
                        widget.showPopularStores || stores.length < 15
                        ? stores.length
                        : 15;
                    return SliverList.builder(
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        final market = stores[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppContentReveal(
                            child: StoreMarketCard(
                              key: ValueKey('${keyPrefix}_${market.id}'),
                              market: market,
                              keyPrefix: keyPrefix,
                              onTap: () => _openStore(market),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
