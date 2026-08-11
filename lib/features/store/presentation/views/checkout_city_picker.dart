import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../location/presentation/cubit/location_cubit.dart';
import 'checkout_icon_tile.dart';
import 'checkout_input_decoration.dart';

const String manualCityOption = '__manual_city__';

Future<String?> openCityPicker({
  required BuildContext context,
  required bool isDark,
  required String? selectedValue,
}) async {
  await context.read<LocationCubit>().loadAvailableCities();
  if (!context.mounted) return null;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.darkCardColor : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return _CityPickerSheet(isDark: isDark, selectedValue: selectedValue);
    },
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({required this.isDark, required this.selectedValue});

  final bool isDark;
  final String? selectedValue;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final cities = context
        .read<LocationCubit>()
        .state
        .availableCities
        .where((city) {
          if (query.isEmpty) return true;
          final english = city.name.toLowerCase();
          final localized = city
              .displayName(arabic: context.isArabicLanguage)
              .toLowerCase();
          return english.contains(query) || localized.contains(query);
        })
        .toList(growable: false);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.68,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.isArabicLanguage
                    ? 'اختار مدينة التوصيل'
                    : 'Choose delivery city',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: checkoutInputDecoration(
                  context: context,
                  isDark: widget.isDark,
                  icon: AppIcons.search_normal,
                  label: context.isArabicLanguage
                      ? 'ابحث عن مدينة'
                      : 'Search city',
                ),
              ),
              const SizedBox(height: 12),
              _CityOptionTile(
                isDark: widget.isDark,
                icon: AppIcons.edit_2,
                title: context.isArabicLanguage
                    ? 'لو مدينتك مش موجودة اكتبها يدوي'
                    : 'If your city is not listed, enter it manually',
                subtitle: context.isArabicLanguage
                    ? 'الشحن هيفضل غير محدد لحد المراجعة'
                    : 'Shipping stays unspecified until review',
                isSelected: widget.selectedValue == manualCityOption,
                onTap: () => Navigator.pop(context, manualCityOption),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: cities.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    return _CityOptionTile(
                      isDark: widget.isDark,
                      icon: AppIcons.location,
                      title: city.displayName(arabic: context.isArabicLanguage),
                      subtitle: context.isArabicLanguage
                          ? 'متاح لها التوصيل'
                          : 'Delivery available',
                      isSelected: widget.selectedValue == city.slug,
                      onTap: () => Navigator.pop(context, city.slug),
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

class _CityOptionTile extends StatelessWidget {
  const _CityOptionTile({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08)
          : (isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFF7F8FB)),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.42)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            children: [
              CheckoutIconTile(icon: icon, isDark: isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: AppFontSizes.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  AppIcons.tick_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
