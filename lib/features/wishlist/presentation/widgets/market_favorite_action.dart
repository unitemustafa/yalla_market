import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/snackbars/custom_snackbar.dart';
import '../../../store/domain/entities/store_data.dart';
import '../cubit/market_wishlist_cubit.dart';

Future<void> toggleMarketFavoriteWithFeedback({
  required BuildContext context,
  required MarketWishlistCubit cubit,
  required StoreMarketData market,
}) async {
  final favorite = await cubit.toggle(market);
  if (!context.mounted) return;

  if (favorite == true) {
    CustomSnackBar.showAdded(
      context: context,
      title: 'Store added to favorites',
    );
    return;
  }
  if (favorite == false) {
    CustomSnackBar.showRemoved(
      context: context,
      title: 'Store removed from favorites',
    );
    return;
  }

  final message = cubit.state.errorMessage;
  if (message?.isNotEmpty == true) {
    CustomSnackBar.showError(
      context: context,
      title: 'Could not update favorite stores',
      message: message,
    );
  }
}
