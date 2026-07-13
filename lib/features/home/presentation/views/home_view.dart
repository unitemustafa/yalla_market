import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/address_required_error.dart';
import '../../../../core/errors/region_required_error.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/images/app_avatar.dart';
import '../../../../core/presentation/widgets/products/cart_counter_icon.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../../../core/routing/app_route_arguments.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/presentation/widgets/texts/section_heading.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../../../location/domain/entities/city_data.dart';
import '../../../location/presentation/cubit/location_cubit.dart';
import '../../../location/presentation/cubit/location_state.dart';
import '../../../personalization/presentation/controllers/user_profile_controller.dart';
import '../../../store/presentation/cubit/product_catalog_cubit.dart';
import '../../../store/presentation/cubit/product_discovery_cubit.dart';
import '../../../store/presentation/cubit/store_cubit.dart';
import '../widgets/home_categories.dart';
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
      _loadHomeData(force: true);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('هذا العرض لم يعد متاحًا')));
    }
    await context.read<ProductCatalogCubit>().loadProducts(force: force);
    if (!mounted) return;
    await context.read<ProductDiscoveryCubit>().loadDiscovery(force: force);
    if (!mounted) return;
    await context.read<StoreCubit>().loadStore(force: force);
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadHomeData(force: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeTopBar(isDark: isDark),
                const SizedBox(height: 18),
                _HomeSearchField(isDark: isDark),
                const SizedBox(height: 22),
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
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (homeState is HomeFailure && home == null) ...[
                          AppErrorState(
                            title: 'Home could not load',
                            message: homeState.message,
                            onRetry: () => _loadHomeData(force: true),
                          ),
                          const SizedBox(height: 22),
                        ],
                        PromoSlider(
                          offers: home?.offers,
                          focusOfferId: widget.focusOfferId,
                        ),
                        const SizedBox(height: 24),
                        const SectionHeading(
                          title: 'Popular Categories',
                          showActionButton: false,
                          titleFontSize: 18,
                        ),
                        const SizedBox(height: 12),
                        HomeCategories(categories: home?.categories),
                        const SizedBox(height: 22),
                        const SectionHeading(
                          title: 'Popular Products',
                          titleFontSize: 18,
                          showActionButton: false,
                        ),
                        const SizedBox(height: 14),
                        HomeProductsSlider(
                          products: home?.products,
                          limit: 6,
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
                        const SizedBox(height: 22),
                        const SectionHeading(
                          title: 'Latest Products',
                          titleFontSize: 18,
                          showActionButton: false,
                        ),
                        const SizedBox(height: 14),
                        HomeProductsSlider(
                          mode: HomeProductsSliderMode.latest,
                          limit: 6,
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
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
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
              color: AppColors.primary.withValues(alpha: isDark ? 0.20 : 0.10),
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
                      color: AppColors.primary.withValues(alpha: 0.12),
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
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.cart);
                },
                iconColor: isDark ? Colors.white : AppColors.lightTextPrimary,
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
      height: 46,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AnimatedCustomerName(name: customerName),
          const SizedBox(height: 1),
          _HomeRegionBadge(label: regionLabel),
        ],
      ),
    );
  }
}

class _AnimatedCustomerName extends StatefulWidget {
  const _AnimatedCustomerName({required this.name});

  final String name;

  @override
  State<_AnimatedCustomerName> createState() => _AnimatedCustomerNameState();
}

class _AnimatedCustomerNameState extends State<_AnimatedCustomerName>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: AppColors.primary,
          end: const Color(0xFF7583FF),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFF7583FF),
          end: const Color(0xFF3B82F6),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFF3B82F6),
          end: const Color(0xFF6366F1),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFF6366F1),
          end: AppColors.primary,
        ),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Text(
          widget.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: _colorAnimation.value,
            fontSize: 14,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        );
      },
    );
  }
}

class _HomeRegionBadge extends StatelessWidget {
  const _HomeRegionBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: AppColors.warning.withValues(alpha: isDark ? 0.18 : 0.12),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.warning,
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
          width: 42,
          height: 42,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(icon, size: 21),
              ),
              if (normalizedBadgeCount > 0)
                PositionedDirectional(
                  key: const ValueKey('notification_unread_badge'),
                  top: -6,
                  end: -6,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
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
                        fontSize: 10,
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

class _HomeSearchField extends StatelessWidget {
  const _HomeSearchField({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Material(
      color: isDark ? AppColors.darkCardColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.search);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
              Icon(AppIcons.search_normal, color: mutedColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('Search products and categories...'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.20 : 0.10,
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
