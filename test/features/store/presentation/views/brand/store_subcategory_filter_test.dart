import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_products_view.dart';

void main() {
  test(
    'All keeps inactive-category products and a category filters locally',
    () {
      final products = [
        ProductData.fromJson({'id': 1, 'name': 'Water', 'subcategory_id': 10}),
        ProductData.fromJson({
          'id': 2,
          'name': 'Hidden legacy product',
          'subcategory_id': 99,
        }),
      ];

      expect(productsForStoreSubcategory(products, null), hasLength(2));
      expect(
        productsForStoreSubcategory(products, '10').map((item) => item.id),
        ['1'],
      );
      expect(productsForStoreSubcategory(products, '20'), isEmpty);
    },
  );
}
