import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
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
  const NavigationMenuView({super.key, this.initialIndex = 0});

  final int initialIndex;

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

  final screens = [
    const HomeView(),
    const StoreView(), // Store
    const WishlistView(), // Wishlist
    const SettingsView(), // Profile
  ];

  @override
  void initState() {
    super.initState();
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
        title: 'Region not changed',
        message: 'Could not update your region. Your cart was not changed.',
      );
      return;
    }

    await context.read<CartCubit>().clearLocalCart();
    if (!mounted) return;
    await Future.wait([
      context.read<HomeCubit>().loadHome(force: true),
      context.read<ProductCatalogCubit>().loadProducts(force: true),
      context.read<ProductDiscoveryCubit>().loadDiscovery(force: true),
      context.read<StoreCubit>().loadStore(force: true),
    ]);
    if (!mounted) return;
    CustomSnackBar.showPersistentSuccess(
      context: context,
      title: selectedCity.isGeneral ? 'General region saved' : 'Region saved',
      message: 'Your cart was cleared and content was refreshed.',
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
      builder: (dialogContext) => AlertDialog(
        title: Text(
          unsupported
              ? dialogContext.tr('Outside service cities')
              : dialogContext.tr('Location changed'),
          textAlign: TextAlign.center,
        ),
        content: Text(
          unsupported
              ? dialogContext.tr(
                  'You are outside our current service cities. Switch your region to General? Changing region will clear your cart.',
                )
              : dialogContext.tr(
                  'Your current region is $currentLabel. We detected $detectedLabel. Changing region will clear your cart.',
                ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('Keep current region')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr('Change region')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _regionLabel(CityData? city) {
    if (city == null || city.isGeneral) return context.tr('General');
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
