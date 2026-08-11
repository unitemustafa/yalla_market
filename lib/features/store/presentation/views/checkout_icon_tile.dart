import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class CheckoutIconTile extends StatelessWidget {
  const CheckoutIconTile({super.key, required this.icon, required this.isDark});

  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColors.primary, size: 18),
    );
  }
}
