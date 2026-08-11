import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/address_required_error.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../core/presentation/widgets/brands/category_tile.dart';
import '../../../../core/presentation/widgets/layouts/grid_layout.dart';
import '../../../../core/presentation/widgets/products/cart_counter_icon.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../core/presentation/widgets/texts/section_heading.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/store_data.dart';
import '../cubit/store_cubit.dart';
import '../cubit/store_state.dart';

class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  Future<void> _refreshStore() {
    return context.read<StoreCubit>().loadStore(force: true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StoreCubit>().loadStore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return BlocBuilder<StoreCubit, StoreState>(
      builder: (context, state) {
        final store = state.data;
        final classifications = store?.classifications ?? const [];

        if (state is StoreLoading && store == null) {
          return _StorePlainScaffold(
            backgroundColor: backgroundColor,
            isDark: isDark,
            onRefresh: _refreshStore,
            child: AppLoadingState(message: context.tr('Loading store...')),
          );
        }

        if (state is StoreFailure && store == null) {
          final requiresAddress = state.message == addressRequiredMessage;
          return _StorePlainScaffold(
            backgroundColor: backgroundColor,
            isDark: isDark,
            onRefresh: _refreshStore,
            child: requiresAddress
                ? AppStateView(
                    icon: AppIcons.location_add,
                    title: context.tr('Address required'),
                    message: context.tr(addressRequiredMessage),
                    actionLabel: context.tr('Add Address'),
                    onAction: () async {
                      await Navigator.pushNamed(context, AppRoutes.addresses);
                      if (context.mounted) await _refreshStore();
                    },
                  )
                : AppErrorState(
                    title: context.tr('Store could not load'),
                    message: context.tr(state.message),
                    onRetry: _refreshStore,
                  ),
          );
        }

        if (classifications.isEmpty) {
          return _StorePlainScaffold(
            backgroundColor: backgroundColor,
            isDark: isDark,
            onRefresh: _refreshStore,
            child: AppEmptyState(
              title: context.tr('No store categories'),
              message: context.tr(
                'Categories will appear here once stores are available.',
              ),
              icon: AppIcons.shop,
            ),
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: AppRefreshIndicator(
              onRefresh: _refreshStore,
              child: CustomScrollView(
                key: const ValueKey('store_categories_scroll'),
                physics: AppRefreshIndicator.scrollPhysics,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StoreTopBar(isDark: isDark),
                          const SizedBox(height: 18),
                          _StoreSearchField(isDark: isDark),
                          const SizedBox(height: 22),
                          const SectionHeading(
                            title: 'Categories',
                            titleFontSize: 17,
                            showActionButton: false,
                          ),
                          const SizedBox(height: 12),
                          _StoreCategoriesGrid(categories: classifications),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StorePlainScaffold extends StatelessWidget {
  const _StorePlainScaffold({
    required this.backgroundColor,
    required this.isDark,
    required this.onRefresh,
    required this.child,
  });

  final Color backgroundColor;
  final bool isDark;
  final RefreshCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AppRefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: AppRefreshIndicator.scrollPhysics,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StoreTopBar(isDark: isDark),
                const SizedBox(height: 18),
                _StoreSearchField(isDark: isDark),
                const SizedBox(height: 24),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreCategoriesGrid extends StatelessWidget {
  const _StoreCategoriesGrid({required this.categories});

  final List<StoreClassificationData> categories;

  @override
  Widget build(BuildContext context) {
    return GridLayout(
      key: const ValueKey('all_store_categories_grid'),
      itemCount: categories.length,
      mainAxisExtent: 106,
      minimumCardWidth: 72,
      minCrossAxisCount: 4,
      maxCrossAxisCount: 4,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryTile(
          key: ValueKey('store_category_${category.id}'),
          name: category.name,
          image: category.image,
          accentColor: Color(category.accentColorValue),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.brandProducts,
              arguments: BrandProductsRouteArgs(
                brand: category.name,
                logo: category.image,
                productCount: category.marketCountLabel,
                classificationId: category.id,
              ),
            );
          },
        );
      },
    );
  }
}

class _StoreTopBar extends StatelessWidget {
  const _StoreTopBar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Store'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('Categories'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: CartCounterIcon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            iconColor: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _StoreSearchField extends StatelessWidget {
  const _StoreSearchField({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final panelColor = isDark ? AppColors.darkCardColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Material(
      color: panelColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.search),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(AppIcons.search_normal, color: mutedColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('Search categories, products...'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.18 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  AppIcons.filter_search,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
