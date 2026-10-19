import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/products/product_cards_sliver.dart';
import '../../../../core/presentation/widgets/products/product_results_view.dart'
    show productCardId, productCardTileData;
import '../../../../core/presentation/widgets/states/app_skeleton.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../../domain/entities/product_data.dart';
import '../cubit/store_products_cubit.dart';
import 'store_products_footer.dart';

class StoreProductsSliver extends StatelessWidget {
  const StoreProductsSliver({
    super.key,
    required this.categoryKey,
    this.emptyTitle = 'No products available',
    this.emptyMessage = 'Products will appear here once this store is ready.',
  });
  final Object categoryKey;
  final String emptyTitle;
  final String emptyMessage;
  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      BlocSelector<
        StoreProductsCubit,
        StoreProductsState,
        (List<ProductData>, bool, String?, Object?, bool)
      >(
        selector: (s) => (
          s.visibleProducts,
          s.isLoading && s.products.isEmpty,
          s.products.isEmpty ? s.error : null,
          s.selectionKey,
          s.hasMore,
        ),
        builder: (context, content) {
          if (content.$2) {
            return const SliverToBoxAdapter(child: AppProductSkeletonGrid());
          }
          if (content.$3 != null) {
            return SliverToBoxAdapter(
              child: AppErrorState(
                title: 'Could not load products',
                message: content.$3!,
                onRetry: context.read<StoreProductsCubit>().retry,
              ),
            );
          }
          if (content.$1.isEmpty) {
            if (content.$5) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverToBoxAdapter(
              child: AppEmptyState(title: emptyTitle, message: emptyMessage),
            );
          }
          return ProductCardsSliver<ProductData>(
            products: content.$1,
            idOf: productCardId,
            cardOf: productCardTileData,
            categoryKey: content.$4 ?? categoryKey,
          );
        },
      ),
      const SliverToBoxAdapter(child: StoreProductsFooter()),
    ],
  );
}
