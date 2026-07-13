import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/routing/app_navigator.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../home/presentation/views/home_view.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../location/domain/entities/city_data.dart';
import '../../../location/presentation/cubit/location_cubit.dart';
import '../../../store/presentation/cubit/product_catalog_cubit.dart';
import '../../../store/presentation/cubit/product_discovery_cubit.dart';
import '../../../store/presentation/cubit/store_cubit.dart';
import '../../../store/presentation/views/store_view.dart';
import '../../../wishlist/presentation/views/wishlist_view.dart';
import '../../../personalization/presentation/views/settings/settings_view.dart';

class NavigationMenuView extends StatefulWidget {
  const NavigationMenuView({
    super.key,
    this.initialIndex = 0,
    this.focusOfferId,
  });

  final int initialIndex;
  final String? focusOfferId;

  @override
  State<NavigationMenuView> createState() => _NavigationMenuViewState();
}

class _NavigationMenuViewState extends State<NavigationMenuView> {
  late int selectedIndex;

  static const _items = [
    _NavigationItemData(
      label: 'Home',
      icon: AppIcons.home,
      activeIcon: AppIcons.home5,
    ),
    _NavigationItemData(
      label: 'Store',
      icon: AppIcons.shop,
      activeIcon: AppIcons.shop5,
    ),
    _NavigationItemData(
      label: 'Wishlist',
      icon: AppIcons.heart,
      activeIcon: AppIcons.heart5,
    ),
    _NavigationItemData(
      label: 'Profile',
      icon: AppIcons.profile_circle,
      activeIcon: AppIcons.profile_circle5,
    ),
  ];

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      HomeView(focusOfferId: widget.focusOfferId),
      const StoreView(),
      const WishlistView(),
      const SettingsView(),
    ];
    selectedIndex = widget.initialIndex.clamp(0, screens.length - 1).toInt();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runOneTimeGpsSuggestion();
    });
  }

  Future<void> _runOneTimeGpsSuggestion() async {
    final locationCubit = context.read<LocationCubit>();
    if (locationCubit.state.selectedCity == null) return;
    if (!locationCubit.consumeGpsSuggestionSlot()) return;

    final detection = await locationCubit.detectMarketRegionSuggestion();
    if (!mounted || detection == null) return;

    switch (detection.action) {
      case GpsRegionAction.sameRegion:
        return;
      case GpsRegionAction.selectDetectedRegion:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.selectCity,
          (route) => false,
        );
        return;
      case GpsRegionAction.suggestSwitch:
        await _handleSuggestedSwitch(detection);
        return;
      case GpsRegionAction.unsupportedLocation:
        await _handleUnsupportedLocation(detection);
        return;
      case GpsRegionAction.unknown:
        return;
    }
  }

  Future<void> _handleSuggestedSwitch(GpsRegionDetection detection) async {
    final locationCubit = context.read<LocationCubit>();
    final current =
        detection.currentSelection?.city ?? locationCubit.state.selectedCity;
    final detected = detection.detectedRegion?.city;
    if (detected == null) return;
    if (locationCubit.wasSuggestionDismissed(current, detected)) return;

    final accepted = await _showSwitchRegionDialog(
      currentLabel: _regionLabel(current),
      detectedLabel: _regionLabel(detected),
      unsupported: false,
    );
    if (!mounted) return;
    if (!accepted) {
      locationCubit.markSuggestionDismissed(current, detected);
      return;
    }

    await _applyRegionChange(detected.withSource(RegionSource.gps));
  }

  Future<void> _handleUnsupportedLocation(GpsRegionDetection detection) async {
    final locationCubit = context.read<LocationCubit>();
    final current =
        detection.currentSelection?.city ?? locationCubit.state.selectedCity;
    if (locationCubit.wasSuggestionDismissed(current, CityData.general)) return;

    final accepted = await _showSwitchRegionDialog(
      currentLabel: _regionLabel(current),
      detectedLabel: context.tr('General'),
      unsupported: true,
    );
    if (!mounted) return;
    if (!accepted) {
      locationCubit.markSuggestionDismissed(current, CityData.general);
      return;
    }

    await _applyRegionChange(CityData.general);
  }

  Future<void> _applyRegionChange(CityData city) async {
    final selectedCity = await context.read<LocationCubit>().selectCity(
      city,
      source: city.source,
    );
    if (!mounted || selectedCity == null) {
      final snackContext = AppNavigator.key.currentContext;
      if (snackContext == null) return;
      if (!snackContext.mounted) return;
      CustomSnackBar.showError(
        context: snackContext,
        title: snackContext.tr('Region not changed'),
        message: snackContext.tr(
          'Could not update your region. Your cart was not changed.',
        ),
      );
      return;
    }

    final cartCleared = await context.read<CartCubit>().clearLocalCart();
    if (!mounted) return;
    await Future.wait([
      context.read<HomeCubit>().loadHome(force: true),
      context.read<ProductCatalogCubit>().loadProducts(force: true),
      context.read<ProductDiscoveryCubit>().loadDiscovery(force: true),
      context.read<StoreCubit>().loadStore(force: true),
    ]);
    if (!mounted) return;
    if (cartCleared) {
      CustomSnackBar.showSuccess(
        context: context,
        title: context.tr(
          selectedCity.isGeneral ? 'General region saved' : 'Region saved',
        ),
        message: context.tr('Your cart was cleared and content was refreshed.'),
      );
      return;
    }

    CustomSnackBar.showError(
      context: context,
      title: context.tr(
        selectedCity.isGeneral ? 'General region saved' : 'Region saved',
      ),
      message: context.tr(
        'The region was changed, but the cart could not be cleared.',
      ),
    );
  }

  Future<bool> _showSwitchRegionDialog({
    required String currentLabel,
    required String detectedLabel,
    required bool unsupported,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _RegionSwitchDialog(
        currentLabel: currentLabel,
        detectedLabel: detectedLabel,
        unsupported: unsupported,
        onKeepCurrent: () => Navigator.pop(dialogContext, false),
        onChangeRegion: () => Navigator.pop(dialogContext, true),
      ),
    );
    return result ?? false;
  }

  String _regionLabel(CityData? city) {
    if (city == null) return '';
    if (city.isGeneral) return context.tr('General');
    return city.displayName(arabic: context.isArabicLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: _YallaBottomNavigationBar(
        items: _items,
        selectedIndex: selectedIndex,
        onSelected: (index) => setState(() => selectedIndex = index),
      ),
    );
  }
}

class _RegionSwitchDialog extends StatelessWidget {
  const _RegionSwitchDialog({
    required this.currentLabel,
    required this.detectedLabel,
    required this.unsupported,
    required this.onKeepCurrent,
    required this.onChangeRegion,
  });

  final String currentLabel;
  final String detectedLabel;
  final bool unsupported;
  final VoidCallback onKeepCurrent;
  final VoidCallback onChangeRegion;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkCardColor : Colors.white;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final safeCurrentLabel = currentLabel.trim().isEmpty
        ? context.currentRegionFallback
        : currentLabel;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.18 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      AppIcons.location,
                      color: AppColors.primary,
                      size: 21,
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  context.regionSwitchTitle(unsupported: unsupported),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  context.regionSwitchMessage(
                    currentRegion: safeCurrentLabel,
                    detectedRegion: detectedLabel,
                    unsupported: unsupported,
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(
                      alpha: isDark ? 0.16 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.shopping_cart,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.cartClearedRegionWarning,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: textColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: AppActionButton(
                        label: context.changeToRegion(detectedLabel),
                        icon: AppIcons.tick_circle,
                        onPressed: onChangeRegion,
                        textStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                        horizontalPadding: 6,
                        verticalPadding: 10,
                        iconSize: 14,
                        iconSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppActionButton(
                        label: context.keepCurrentRegion(safeCurrentLabel),
                        icon: AppIcons.arrow_left_2,
                        variant: AppActionButtonVariant.outlined,
                        onPressed: onKeepCurrent,
                        textStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                        horizontalPadding: 6,
                        verticalPadding: 10,
                        iconSize: 14,
                        iconSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _YallaBottomNavigationBar extends StatelessWidget {
  const _YallaBottomNavigationBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_NavigationItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.darkCardColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return SafeArea(
      top: false,
      child: Container(
        height: 78,
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: borderColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            return Expanded(
              child: _NavigationBarItem(
                item: items[index],
                isSelected: selectedIndex == index,
                onTap: () => onSelected(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavigationBarItem extends StatelessWidget {
  const _NavigationBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavigationItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final labelColor = isSelected ? AppColors.primary : inactiveColor;
    final indicatorColor = isSelected
        ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.11)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 52,
                height: 32,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: labelColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.tr(item.label),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItemData {
  const _NavigationItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
