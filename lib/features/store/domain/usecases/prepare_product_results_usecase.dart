import '../../../../core/network/api_result.dart';
import '../../../../core/domain/computation_executor.dart';
import '../../../../core/errors/failure.dart';
import '../entities/product_data.dart';

/// Pure catalog calculations. Pagination never needs to repeat this work.
class PrepareProductResultsUseCase {
  const PrepareProductResultsUseCase({
    ComputationExecutor executor = const InlineComputationExecutor(),
  }) : _executor = executor;

  final ComputationExecutor _executor;

  Future<ApiResult<List<ProductData>>> call(
    List<ProductData> products, {
    required String query,
    required String sortOption,

    String? subcategoryId,
  }) async {
    try {
      final data = await _executor.run(_prepare, (
        products: products,
        query: query.trim(),
        sortOption: sortOption,
        subcategoryId: subcategoryId?.trim() ?? '',
      ), background: products.length >= backgroundCatalogThreshold);
      return ApiResult.success(data);
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not prepare products.'),
      );
    }
  }
}

typedef _ProductResultsJob = ({
  List<ProductData> products,
  String query,
  String sortOption,

  String subcategoryId,
});

List<ProductData> _prepare(_ProductResultsJob job) {
  final selected = job.subcategoryId;
  final filtered = job.products.where((product) {
    return product.matches(job.query) &&
        (selected.isEmpty ||
            product.subcategoryId == selected ||
            product.subcategories.any((item) => item.id == selected));
  }).toList();
  switch (job.sortOption) {
    case 'Higher Price' || 'Lower Price':
      final prices = {
        for (final product in filtered) product: product.priceValue,
      };
      filtered.sort(
        (a, b) => job.sortOption == 'Higher Price'
            ? prices[b]!.compareTo(prices[a]!)
            : prices[a]!.compareTo(prices[b]!),
      );
    case 'Newest':
      // The incoming catalog is already newest first.
      break;
    default:
      filtered.sort((a, b) => a.title.compareTo(b.title));
  }
  return List.unmodifiable(filtered);
}
