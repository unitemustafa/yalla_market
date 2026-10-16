import 'package:dio/dio.dart';
import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/product_data.dart';
import '../../domain/entities/store_product_page.dart';
import '../../domain/repositories/store_products_repository.dart';

class StoreProductsRemoteRepositoryImpl implements StoreProductsRepository {
  const StoreProductsRemoteRepositoryImpl(this._client);
  final ApiClient _client;

  @override
  Future<ApiResult<StoreProductPage>> getProducts(
    String marketId, {
    int page = 1,
    int pageSize = 30,
    String query = '',
    String? subcategoryId,
    StoreProductSort sort = StoreProductSort.name,
  }) async {
    try {
      final payload = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.storefrontProducts(marketId),
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          'q': query,
          'sort': sort.apiValue,
          if (subcategoryId != null && subcategoryId.isNotEmpty)
            'subcategory_id': subcategoryId,
        },
      );
      final results = payload['results'];
      final count = payload['count'];
      final next = payload['next'];
      if (results is! List ||
          results.length > pageSize ||
          count is! int ||
          count < 0 ||
          (next != null && (next is! String || next.isEmpty))) {
        throw const FormatException('Invalid store products page');
      }
      final products = results
          .map((raw) {
            if (raw is! Map<String, dynamic> ||
                raw['id'] == null ||
                raw['id'].toString().trim().isEmpty) {
              throw const FormatException('Invalid product');
            }
            return ProductData.fromJson(raw);
          })
          .toList(growable: false);
      return ApiResult.success(
        StoreProductPage(
          products: List.unmodifiable(products),
          count: count,
          hasMore: next != null,
        ),
      );
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load store products.'),
      );
    }
  }
}
