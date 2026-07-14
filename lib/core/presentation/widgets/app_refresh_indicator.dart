import 'package:flutter/material.dart';

import 'snackbars/custom_snackbar.dart';

class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.showSuccessSnackBar = true,
    this.successTitle = 'Content updated',
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  static const ScrollPhysics scrollPhysics = AlwaysScrollableScrollPhysics();

  final RefreshCallback onRefresh;
  final Widget child;
  final bool showSuccessSnackBar;
  final String successTitle;
  final ScrollNotificationPredicate notificationPredicate;

  Future<void> _refresh(BuildContext context) async {
    await onRefresh();
    if (!context.mounted || !showSuccessSnackBar) return;
    CustomSnackBar.showSuccess(context: context, title: successTitle);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      notificationPredicate: notificationPredicate,
      child: child,
    );
  }
}
