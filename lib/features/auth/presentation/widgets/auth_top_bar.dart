import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/appbar/app_navigation_icon_button.dart';

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key, this.showClose = false, this.onClose});

  final bool showClose;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 42, height: 42),
        if (showClose)
          AppNavigationIconButton.close(
            onPressed: onClose ?? () => Navigator.pop(context),
          )
        else
          const SizedBox(width: 42, height: 42),
      ],
    );
  }
}
