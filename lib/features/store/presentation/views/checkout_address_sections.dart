import 'package:flutter/material.dart';

import '../../../../app/routing/app_route_arguments.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../personalization/domain/entities/address.dart';
import 'checkout_section_card.dart';

class SavedAddressCheckoutCard extends StatelessWidget {
  const SavedAddressCheckoutCard({
    super.key,
    required this.address,
    required this.isDark,
  });

  final AddressData? address;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final hasAddress = address != null;

    return CheckoutSectionCard(
      isDark: isDark,
      title: 'Shipping Address',
      icon: AppIcons.location,
      actionLabel: hasAddress ? 'Change' : 'Add',
      onAction: () => Navigator.pushNamed(
        context,
        AppRoutes.addresses,
        arguments: const AddressesRouteArgs(returnAfterSelection: true),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasAddress ? AppIcons.location : AppIcons.location_add,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAddress
                      ? address!.name
                      : context.tr('Choose a saved address'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  hasAddress
                      ? address!.fullAddress
                      : context.tr('Add an address to start checkout faster.'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: AppFontSizes.label,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
