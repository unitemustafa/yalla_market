import '../../../../core/computation/catalog_computation_executor.dart';
import '../../../../core/domain/computation_executor.dart';
import '../../domain/entities/store_data.dart';

class StorefrontDecoder {
  const StorefrontDecoder({
    ComputationExecutor executor = const CatalogComputationExecutor(),
  }) : _executor = executor;

  final ComputationExecutor _executor;

  Future<StoreMarketData> decode(Map<String, dynamic> payload) {
    final products = payload['products'];
    return _executor.run(
      _decode,
      payload,
      background:
          products is List && products.length >= backgroundCatalogThreshold,
    );
  }
}

StoreMarketData _decode(Map<String, dynamic> payload) =>
    StoreMarketData.fromJson(payload);
