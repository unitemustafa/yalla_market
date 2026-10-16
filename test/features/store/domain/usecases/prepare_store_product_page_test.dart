import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_product_page.dart';
import 'package:yalla_market/features/store/domain/usecases/prepare_store_product_page.dart';

void main() {
  final products = [
    _product('3', 'Zebra', '30', 'Fruit', description: 'sweet snack'),
    _product('1', 'Apple', '10', 'Fruit'),
    _product('2', 'Banana', '20', 'Drink', description: 'cold fruit drink'),
  ];

  test('filters descriptions and linked subcategories before paging', () {
    final result = prepareStoreProductPage(
      products,
      page: 1,
      pageSize: 30,
      query: 'cold',
      subcategoryId: 'Drink',
      sort: StoreProductSort.name,
    );

    expect(result.count, 1);
    expect(result.products.map((product) => product.id), ['2']);
  });

  test(
    'sorts deterministically and reports continuation from the filtered count',
    () {
      final first = prepareStoreProductPage(
        products,
        page: 1,
        pageSize: 2,
        query: '',
        subcategoryId: null,
        sort: StoreProductSort.priceDesc,
      );
      final second = prepareStoreProductPage(
        products,
        page: 2,
        pageSize: 2,
        query: '',
        subcategoryId: null,
        sort: StoreProductSort.priceDesc,
      );

      expect(first.products.map((product) => product.id), ['3', '2']);
      expect(first.count, 3);
      expect(first.hasMore, isTrue);
      expect(second.products.map((product) => product.id), ['1']);
      expect(second.hasMore, isFalse);
    },
  );

  test('newest preserves source order', () {
    final result = prepareStoreProductPage(
      products,
      page: 1,
      pageSize: 30,
      query: '',
      subcategoryId: null,
      sort: StoreProductSort.newest,
    );
    expect(result.products.map((product) => product.id), ['3', '1', '2']);
  });
}

ProductData _product(
  String id,
  String title,
  String price,
  String subcategory, {
  String description = '',
}) => ProductData(
  id: id,
  image: '',
  title: title,
  brand: 'Store',
  price: price,
  oldPrice: null,
  discount: '',
  tags: const [],
  description: description,
  subcategoryId: subcategory,
  subcategories: [
    StoreSubcategoryData(
      id: subcategory,
      nameAr: subcategory,
      nameEn: subcategory,
    ),
  ],
);
