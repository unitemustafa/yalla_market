import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/presentation/widgets/app_list_entrance.dart';
import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../../app/routing/app_routes.dart';
import '../../domain/entities/cart_item.dart';
import '../cubit/cart_cubit.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_summary_widgets.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView>
    with SingleTickerProviderStateMixin {
  late final AppListEntranceController _listEntrance;

  @override
  void initState() {
    super.initState();
    _listEntrance = AppListEntranceController(vsync: this);
  }

  @override
  void dispose() {
    _listEntrance.dispose();
    super.dispose();
  }

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

  bool _cartOrderChanged(List<CartItemData> before, List<CartItemData> after) {
    if (before.length != after.length) return true;
    for (var index = 0; index < after.length; index++) {
      if (before[index].id != after[index].id) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.darkBackground
        : const Color(0xFFF7F8FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: BlocSelector<CartCubit, List<CartItemData>, int>(
                selector: _itemCount,
                builder: (context, itemCount) =>
                    _buildCartTopBar(isDark: isDark, itemCount: itemCount),
              ),
            ),
            Expanded(
              child: BlocBuilder<CartCubit, List<CartItemData>>(
                buildWhen: _cartOrderChanged,
                builder: (context, cartItems) {
                  _listEntrance.prepare(
                    cartItems.map((item) => item.id),
                    disableAnimations: MediaQuery.disableAnimationsOf(context),
                  );
                  return cartItems.isEmpty
                      ? const EmptyCartView()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: cartItems.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return AppListEntranceItem(
                              key: ValueKey(item.id),
                              controller: _listEntrance,
                              itemId: item.id,
                              child: Dismissible(
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
                                child:
                                    BlocSelector<
                                      CartCubit,
                                      List<CartItemData>,
                                      CartItemData?
                                    >(
                                      selector: (items) {
                                        if (index < items.length &&
                                            items[index].id == item.id) {
                                          return items[index];
                                        }
                                        for (final current in items) {
                                          if (current.id == item.id) {
                                            return current;
                                          }
                                        }
                                        return null;
                                      },
                                      builder: (context, current) =>
                                          current == null
                                          ? const SizedBox.shrink()
                                          : CartItemCard(
                                              item: current,
                                              isDark: isDark,
                                            ),
                                    ),
                              ),
                            );
                          },
                        );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          BlocSelector<CartCubit, List<CartItemData>, (double, int)?>(
            selector: (items) =>
                items.isEmpty ? null : (_subtotal(items), _itemCount(items)),
            builder: (context, summary) {
              if (summary == null) return const SizedBox.shrink();
              return CheckoutSummary(
                subtotal: summary.$1,
                itemCount: summary.$2,
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
}
