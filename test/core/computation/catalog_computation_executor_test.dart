import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/computation/catalog_computation_executor_native.dart'
    as native;
import 'package:yalla_market/core/domain/computation_executor.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/store/data/mapping/storefront_decoder.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/usecases/prepare_product_results_usecase.dart';

void main() {
  group('CatalogComputationExecutor native isolate', () {
    for (final count in [1000, 10000]) {
      test('matches inline product preparation for $count products', () async {
        final products = List.generate(count, (index) => _product(index));
        final inline = PrepareProductResultsUseCase(
          executor: const InlineComputationExecutor(),
        );
        final isolated = PrepareProductResultsUseCase(
          executor: const native.CatalogComputationExecutor(),
        );

        final expected = await inline(
          products,
          query: 'Product',
          sortOption: 'Higher Price',
        );
        final actual = await isolated(
          products,
          query: 'Product',
          sortOption: 'Higher Price',
        );

        expect(
          _products(actual).map((item) => item.id),
          _products(expected).map((item) => item.id),
        );
      });

      test('matches inline storefront mapping for $count products', () async {
        final payload = <String, dynamic>{
          'id': 'market-1',
          'name': 'Market',
          'products': List.generate(count, _productPayload),
        };
        const inline = StorefrontDecoder(executor: InlineComputationExecutor());
        const isolated = StorefrontDecoder(
          executor: native.CatalogComputationExecutor(),
        );

        final expected = await inline.decode(payload);
        final actual = await isolated.decode(payload);

        expect(actual.id, expected.id);
        expect(actual.products.length, expected.products.length);
        expect(actual.products.first.id, expected.products.first.id);
        expect(actual.products.last.id, expected.products.last.id);
        expect(actual.products.last.price, expected.products.last.price);
      });
    }
  });
}

List<ProductData> _products(ApiResult<List<ProductData>> result) =>
    (result as ApiSuccess<List<ProductData>>).data;

ProductData _product(int index) => ProductData(
  id: '$index',
  image: '',
  title: 'Product $index',
  brand: 'Market',
  price: '${index % 100}.00',
  oldPrice: null,
  discount: '',
  tags: const [],
);

Map<String, Object?> _productPayload(int index) => {
  'id': index,
  'name': 'Product $index',
  'market': {'id': 'market-1', 'name': 'Market'},
  'variants': [
    {'id': index, 'price': '${index % 100}.00'},
  ],
};
