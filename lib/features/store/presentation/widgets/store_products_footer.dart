import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/states/app_state_view.dart';
import '../cubit/store_products_cubit.dart';

class StoreProductsFooter extends StatelessWidget {
  const StoreProductsFooter({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocSelector<StoreProductsCubit, StoreProductsState, (bool, String?)>(
        selector: (s) => (
          s.loadingMore || (s.isLoading && s.products.isNotEmpty),
          s.moreError ?? (s.products.isNotEmpty ? s.error : null),
        ),
        builder: (context, footer) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: footer.$2 != null
              ? AppErrorState(
                  title: 'Could not load products',
                  message: footer.$2!,
                  onRetry: context.read<StoreProductsCubit>().retry,
                )
              : footer.$1
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      );
}
