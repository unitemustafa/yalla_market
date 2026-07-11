import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_translations.dart';
import '../../domain/entities/app_notification.dart';

class NotificationPresentationData {
  const NotificationPresentationData({
    required this.localizedTitle,
    required this.localizedMessage,
    required this.icon,
    required this.color,
  });

  final String localizedTitle;
  final String localizedMessage;
  final IconData icon;
  final Color color;
}

class NotificationPresentationMapper {
  const NotificationPresentationMapper._();

  static NotificationPresentationData map(
    BuildContext context,
    AppNotification notification,
  ) {
    final orderId = '${notification.orderId ?? ''}';
    switch (notification.type) {
      case 'account_restored':
        return NotificationPresentationData(
          localizedTitle: context.tr('Account restored'),
          localizedMessage: context.tr(
            'Your account was restored by the Yalla Market team.',
          ),
          icon: AppIcons.tick_circle,
          color: AppColors.success,
        );
      case 'order_rejected':
        return NotificationPresentationData(
          localizedTitle: context.tr('Order rejected'),
          localizedMessage: context
              .tr('Your order #{orderId} was rejected.')
              .replaceAll('{orderId}', orderId),
          icon: AppIcons.danger,
          color: AppColors.error,
        );
      case 'order_assigned':
        return NotificationPresentationData(
          localizedTitle: context.tr('New order assigned'),
          localizedMessage: context
              .tr('A new order #{orderId} has been assigned to you.')
              .replaceAll('{orderId}', orderId),
          icon: AppIcons.truck_fast,
          color: AppColors.primary,
        );
      case 'new_order_review':
        return NotificationPresentationData(
          localizedTitle: context.tr('New order requires review'),
          localizedMessage: context
              .tr('Order #{orderId} requires admin review.')
              .replaceAll('{orderId}', orderId),
          icon: AppIcons.shopping_bag,
          color: AppColors.warning,
        );
    }

    return NotificationPresentationData(
      localizedTitle: notification.title,
      localizedMessage: notification.message,
      icon: AppIcons.notification,
      color: AppColors.primary,
    );
  }
}
