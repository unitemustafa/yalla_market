import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/widgets/appbar/page_top_bar.dart';
import '../../../../core/presentation/widgets/brands/brand_card.dart';
import '../../../../core/presentation/widgets/layouts/grid_layout.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/store_data.dart';
import '../cubit/store_cubit.dart';
import '../cubit/store_state.dart';

class LatestStoresView extends StatefulWidget {
  const LatestStoresView({super.key});

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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTopBar(
                title: 'Latest Stores',
                subtitle: 'Browse the newest stores',
              ),
              const SizedBox(height: 18),
              BlocBuilder<StoreCubit, StoreState>(
                builder: (context, state) {
                  final stores = state.data?.latestMarkets ?? const [];
                  if (state is StoreLoading && stores.isEmpty) {
                    return const AppLoadingState(message: 'Loading store...');
                  }
                  if (state is StoreFailure && stores.isEmpty) {
                    return AppErrorState(
                      title: 'Store could not load',
                      message: state.message,
                      onRetry: () =>
                          context.read<StoreCubit>().loadStore(force: true),
                    );
                  }
                  if (stores.isEmpty) {
                    return const AppEmptyState(
                      title: 'No stores available',
                      message: 'New stores will appear here once added.',
                    );
                  }

                  return GridLayout(
                    itemCount: stores.length.clamp(0, 15),
                    mainAxisExtent: 92,
                    itemBuilder: (_, index) {
                      final market = stores[index];
                      return BrandCard(
                        showBorder: true,
                        brand: market.name,
                        productCount: market.productCountLabel,
                        logo: market.image,
                        accentColor: Color(market.accentColorValue),
                        onTap: () => _openStore(market),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
