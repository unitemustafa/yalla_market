import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/appbar/app_navigation_icon_button.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/cart_item.dart';
import '../cubit/cart_cubit.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_summary_widgets.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  double _subtotal(List<CartItemData> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  int _itemCount(List<CartItemData> cartItems) {
    return cartItems.fold(
      0,
      (sum, item) =>
          sum +
          (item.isOffer && item.offerProducts.isNotEmpty
              ? item.offerProducts.fold(
                  0,
                  (productSum, product) => productSum + product.quantity,
                )
              : item.quantity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: BlocBuilder<CartCubit, List<CartItemData>>(
        builder: (context, cartItems) {
          final topBar = _buildCartTopBar(
            isDark: isDark,
            itemCount: _itemCount(cartItems),
          );

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: topBar,
                ),
                Expanded(
                  child: cartItems.isEmpty
                      ? const EmptyCartView()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: cartItems.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 22,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: AlignmentDirectional.centerEnd,
                                child: const Icon(
                                  AppIcons.trash,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              onDismissed: (direction) {
                                context.read<CartCubit>().removeItem(item.id);
                                CustomSnackBar.showRemoved(
                                  context: context,
                                  title: 'Item removed from cart',
                                );
                              },
                              child: _buildCartItem(
                                context,
                                item: item,
                                isDark: isDark,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, List<CartItemData>>(
        builder: (context, cartItems) {
          if (cartItems.isEmpty) return const SizedBox.shrink();

          final subtotal = _subtotal(cartItems);

          return CheckoutSummary(
            subtotal: subtotal,
            itemCount: _itemCount(cartItems),
            isDark: isDark,
            onCheckout: () {
              Navigator.pushNamed(context, AppRoutes.checkout);
            },
          );
        },
      ),
    );
  }

  Widget _buildCartTopBar({required bool isDark, required int itemCount}) {
    return Row(
      children: [
        AppNavigationIconButton.back(
          onPressed: () => Navigator.pop(context),
          color: isDark ? Colors.white : Colors.black,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.tr('Cart'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : Colors.black,
              fontSize: AppFontSizes.title,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (itemCount > 0) CartCountBadge(count: itemCount, isDark: isDark),
      ],
    );
  }

  Widget _buildCartItem(
    BuildContext context, {
    required CartItemData item,
    required bool isDark,
  }) {
    return CartItemCard(item: item, isDark: isDark);
  }
}
