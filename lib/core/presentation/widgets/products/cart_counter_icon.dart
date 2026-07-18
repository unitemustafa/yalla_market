import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/cart/domain/entities/cart_item.dart';
import '../../../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../../routing/app_routes.dart';
import '../../../constants/app_colors.dart';

class CartCounterIcon extends StatelessWidget {
  const CartCounterIcon({
    super.key,
    this.onPressed,
    required this.iconColor,
    this.iconSize = 24,
    this.buttonSize = 44,
  });

  final VoidCallback? onPressed;
  final Color iconColor;
  final double iconSize;
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, List<CartItemData>>(
      builder: (context, cartItems) {
        final count = cartItems.fold(0, (sum, item) => sum + item.quantity);

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Center(
              child: IconButton(
                onPressed:
                    onPressed ??
                    () => Navigator.pushNamed(context, AppRoutes.cart),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(
                  width: buttonSize,
                  height: buttonSize,
                ),
                icon: Icon(
                  AppIcons.shopping_bag,
                  color: iconColor,
                  size: iconSize,
                ),
              ),
            ),
            if (count > 0)
              PositionedDirectional(
                end: 2,
                top: 2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkCardColor
                          : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: AppFontSizes.caption,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
