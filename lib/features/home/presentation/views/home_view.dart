import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/address_required_error.dart';
import '../../../../core/errors/region_required_error.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/app_refresh_indicator.dart';
import '../../../../core/presentation/widgets/images/app_avatar.dart';
import '../../../../core/presentation/widgets/products/cart_counter_icon.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/presentation/widgets/texts/section_heading.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../../domain/entities/home_data.dart';
import '../../../location/domain/entities/city_data.dart';
import '../../../location/presentation/cubit/location_cubit.dart';
import '../../../location/presentation/cubit/location_state.dart';
import '../../../personalization/presentation/controllers/user_profile_controller.dart';
import '../../../store/domain/entities/category_data.dart';
import '../../../store/domain/entities/product_data.dart';
import '../../../store/presentation/cubit/product_catalog_cubit.dart';
import '../../../store/presentation/cubit/product_catalog_state.dart';
import '../widgets/home_categories.dart';
import '../widgets/home_benefits_strip.dart';
import '../widgets/home_popular_products_slider.dart';
import '../widgets/promo_slider.dart';

@visibleForTesting
String homeRegionLabel(BuildContext context, CityData? city) {
  if (city == null) return '';
  if (city.isGeneral) return context.tr('General');
  return city.displayName(arabic: context.isArabicLanguage);
}

class HomeView extends StatefulWidget {
  const HomeView({super.key, this.focusOfferId});

  final String? focusOfferId;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _reportedMissingOffer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadHomeData(force: widget.focusOfferId?.trim().isNotEmpty == true);
    });
  }

  Future<void> _loadHomeData({bool force = false}) async {
    await context.read<HomeCubit>().loadHome(force: force);
    if (!mounted) return;
    final homeState = context.read<HomeCubit>().state;
    if (homeState is HomeFailure &&
        homeState.message == regionRequiredMessage) {
      _goToSelectCity();
      return;
    }
    if (homeState is HomeFailure && homeState.data == null) {
      return;
    }
    final focusOfferId = widget.focusOfferId;
    final offers = homeState.data?.offers ?? const [];
    if (focusOfferId != null &&
        focusOfferId.isNotEmpty &&
        offers.every((offer) => offer.id != focusOfferId) &&
        !_reportedMissingOffer) {
      _reportedMissingOffer = true;
      CustomSnackBar.showWarning(
        context: context,
        title: 'This offer is not available in your city right now.',
      );
    }
    await context.read<ProductCatalogCubit>().loadProducts(force: force);
  }

  Future<void> _openAddresses() async {
    await Navigator.pushNamed(context, AppRoutes.addresses);
    if (mounted) await _loadHomeData(force: true);
  }

  void _goToSelectCity() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.selectCity,
      (route) => false,
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
      body: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            height: 380,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary,
                    const Color(0xFF07599B),
                    backgroundColor,
                  ],
                  stops: const [0, 0.52, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: AppRefreshIndicator(
              onRefresh: () => _loadHomeData(force: true),
              child: SingleChildScrollView(
                physics: AppRefreshIndicator.scrollPhysics,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeTopBar(isDark: isDark),
                        const SizedBox(height: 18),
                        _HomeSearchActionsRow(isDark: isDark),
                        const SizedBox(height: 12),
                        const HomeBenefitsStrip(),
                        const SizedBox(height: 12),
                        BlocConsumer<HomeCubit, HomeState>(
                          listener: (context, homeState) {
                            if (homeState is HomeFailure &&
                                homeState.message == regionRequiredMessage) {
                              _goToSelectCity();
                            }
                          },
                          builder: (context, homeState) {
                            final home = homeState.data;
                            if (homeState is HomeFailure &&
                                home == null &&
                                homeState.message == addressRequiredMessage) {
                              return AppStateView(
                                icon: AppIcons.location_add,
                                title: 'Delivery address needed',
                                message: addressRequiredMessage,
                                actionLabel: 'Review address',
                                onAction: _openAddresses,
                                showActionIcon: false,
                              );
                            }
                            if (homeState is HomeFailure && home == null) {
                              return AppErrorState(
                                title: 'Home could not load',
                                message: homeState.message,
                                onRetry: () => _loadHomeData(force: true),
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PromoSlider(
                                  offers: home?.offers,
                                  focusOfferId: widget.focusOfferId,
                                ),
                                const SizedBox(height: 24),
                                BlocBuilder<
                                  ProductCatalogCubit,
                                  ProductCatalogState
                                >(
                                  builder: (context, catalogState) {
                                    return HomeCatalogSections(
                                      home: home,
                                      catalogState: catalogState,
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
class HomeCatalogSections extends StatelessWidget {
  const HomeCatalogSections({
    super.key,
    required this.home,
    required this.catalogState,
  });

  final HomeData? home;
  final ProductCatalogState catalogState;

  @override
  Widget build(BuildContext context) {
    final popularProducts = (home?.products ?? const <ProductData>[])
        .where((product) => product.isPopular)
        .toList(growable: false);
    final latestProducts = catalogState is ProductCatalogReady
        ? (catalogState as ProductCatalogReady).products
        : const <ProductData>[];
    final categories = home?.categories ?? const <CategoryData>[];

    if (categories.isEmpty &&
        popularProducts.isEmpty &&
        latestProducts.isEmpty) {
      if (catalogState is ProductCatalogInitial ||
          catalogState is ProductCatalogLoading) {
        return const AppLoadingState(message: 'Loading products...');
      }
      if (catalogState is ProductCatalogFailure) {
        return AppErrorState(
          title: 'Products could not load',
          message: (catalogState as ProductCatalogFailure).message,
          onRetry: () =>
              context.read<ProductCatalogCubit>().loadProducts(force: true),
        );
      }
      if (catalogState is ProductCatalogNeedsCity) {
        return const AppEmptyState(
          title: 'Choose your city',
          message: 'So we can show products available in your area.',
        );
      }
      return const AppEmptyState(
        key: ValueKey('home_empty_products'),
        title: 'No products available',
        message: 'Products will appear here once the catalog is ready.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categories.isNotEmpty) ...[
          SectionHeading(
            title: 'Popular Categories',
            showActionButton: categories.length > 4,
            titleFontSize: AppFontSizes.sectionTitle,
            onPressed: categories.length > 4
                ? () => Navigator.pushNamed(
                    context,
                    AppRoutes.categories,
                    arguments: CategoriesRouteArgs(categories: categories),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          HomeCategories(categories: categories),
        ],
        if (popularProducts.isNotEmpty) ...[
          if (categories.isNotEmpty) const SizedBox(height: 22),
          const SectionHeading(
            title: 'Popular Products',
            titleFontSize: AppFontSizes.sectionTitle,
            showActionButton: false,
          ),
          const SizedBox(height: 14),
          HomeProductsSlider(
            products: popularProducts,
            limit: 5,
            onViewAll: () {
              Navigator.pushNamed(
                context,
                AppRoutes.allProducts,
                arguments: const AllProductsRouteArgs(
                  collection: ProductCollectionType.popular,
                ),
              );
            },
          ),
        ],
        if (latestProducts.isNotEmpty) ...[
          if (categories.isNotEmpty || popularProducts.isNotEmpty)
            const SizedBox(height: 22),
          const SectionHeading(
            title: 'Latest Products',
            titleFontSize: AppFontSizes.sectionTitle,
            showActionButton: false,
          ),
          const SizedBox(height: 14),
          HomeProductsSlider(
            products: latestProducts,
            mode: HomeProductsSliderMode.latest,
            limit: 5,
            onViewAll: () {
              Navigator.pushNamed(
                context,
                AppRoutes.allProducts,
                arguments: const AllProductsRouteArgs(
                  title: 'Latest Products',
                  subtitle: 'Browse the latest products',
                  collection: ProductCollectionType.latest,
                  maxItems: 15,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfileController>(
      valueListenable: UserProfileController.instance,
      builder: (context, profile, _) {
        return Row(
          children: [
            Material(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.18),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: _TopProfileAvatar(profile: profile),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BlocBuilder<LocationCubit, LocationState>(
                builder: (context, state) {
                  return _HomeCustomerSummary(
                    customerName: profile.displayName,
                    regionLabel: homeRegionLabel(context, state.selectedCity),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              key: const ValueKey('home_brand_logo'),
              width: 112,
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  AppAssets.homeBrandLogo,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.02),
                  cacheWidth: 196,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HomeCustomerSummary extends StatelessWidget {
  const _HomeCustomerSummary({
    required this.customerName,
    required this.regionLabel,
  });

  final String customerName;
  final String regionLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.tr('Welcome'),
            key: const ValueKey('home_welcome_label'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: AppFontSizes.caption,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontSize: AppFontSizes.body,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          _HomeRegionBadge(label: regionLabel),
        ],
      ),
    );
  }
}

class _HomeRegionBadge extends StatelessWidget {
  const _HomeRegionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            AppIcons.location,
            key: ValueKey('home_region_icon'),
            color: AppColors.warning,
            size: 14,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: AppFontSizes.caption,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProfileAvatar extends StatelessWidget {
  const _TopProfileAvatar({required this.profile});

  final UserProfileController profile;

  @override
  Widget build(BuildContext context) {
    return AppAvatar(
      initials: profile.initials,
      imageBytes: profile.avatarBytes,
      imageUrl: profile.avatarUrl,
      gender: profile.gender,
      size: 46,
      borderRadius: 7,
      borderColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      textScale: 0.35,
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    super.key,
    required this.isDark,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final normalizedBadgeCount = badgeCount < 0 ? 0 : badgeCount;
    return Material(
      color: isDark ? AppColors.darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(icon, size: 20),
              ),
              if (normalizedBadgeCount > 0)
                PositionedDirectional(
                  key: const ValueKey('notification_unread_badge'),
                  top: -6,
                  end: -6,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkCardColor : Colors.white,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      normalizedBadgeCount > 99
                          ? '99+'
                          : '$normalizedBadgeCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: AppFontSizes.caption,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSearchActionsRow extends StatelessWidget {
  const _HomeSearchActionsRow({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.ltr,
      children: [
        Expanded(child: _HomeSearchField(isDark: isDark)),
        const SizedBox(width: 8),
        BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            return _TopActionButton(
              key: const ValueKey('notification_bell_button'),
              isDark: isDark,
              icon: AppIcons.notification,
              badgeCount: state.unreadCount,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.notifications);
              },
            );
          },
        ),
        const SizedBox(width: 8),
        Container(
          key: const ValueKey('home_cart_button'),
          width: 46,
          height: 46,
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
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.cart);
            },
            iconColor: isDark ? Colors.white : AppColors.lightTextPrimary,
            iconSize: 20,
            buttonSize: 38,
          ),
        ),
      ],
    );
  }
}

class _HomeSearchField extends StatelessWidget {
  const _HomeSearchField({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Material(
      key: const ValueKey('home_search_field'),
      color: isDark ? AppColors.darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.search);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(AppIcons.search_normal, color: mutedColor, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.tr('Search products and categories...'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontSize: AppFontSizes.small,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  AppIcons.filter_search,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
