import 'package:flutter/widgets.dart';

import '../../../../core/localization/app_translations.dart';

class NotificationTimeFormatter {
  const NotificationTimeFormatter._();

  static String format(
    BuildContext context,
    DateTime createdAt, {
    DateTime? now,
  }) {
    final localCreatedAt = createdAt.toLocal();
    final localNow = (now ?? DateTime.now()).toLocal();
    final difference = localNow.difference(localCreatedAt);

    if (difference.inMinutes < 1) return context.tr('Just now');
    if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      final key = minutes == 1 ? 'min ago' : 'mins ago';
      return '$minutes ${context.tr(key)}';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      final key = hours == 1 ? 'hour ago' : 'hours ago';
      return '$hours ${context.tr(key)}';
    }
    if (difference.inDays == 1) return context.tr('Yesterday');
    return '${difference.inDays} ${context.tr('days ago')}';
  }
}
