import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';

void main() {
  group('ProductData', () {
    test('keeps remote imageUrl values unchanged', () {
      const imageUrl = 'https://cdn.example.com/products/product_1.png';

      final product = ProductData.fromJson({
        'id': 'product_1',
        'code': 'PRD-A1B2C3',
        'imageUrl': imageUrl,
        'title': 'Running Shoe',
        'brand': 'Yalla',
        'price': '1200 EGP',
      });

      expect(product.image, imageUrl);
      expect(product.code, 'PRD-A1B2C3');
      expect(product.toJson()['code'], 'PRD-A1B2C3');
    });

    test('parses city metadata from API payloads', () {
      final product = ProductData.fromJson({
        'id': 'product_1',
        'image': 'shoe.png',
        'title': 'Running Shoe',
        'brand': 'Yalla',
        'price': '1200 EGP',
        'citySlug': 'sharm-el-sheikh',
        'cityName': 'Sharm El Sheikh',
      });

      expect(product.citySlug, 'sharm-el-sheikh');
      expect(product.cityName, 'Sharm El Sheikh');
      expect(product.toJson()['citySlug'], 'sharm-el-sheikh');
    });

    test('parses variants and exposes the default variant', () {
      final product = ProductData.fromJson({
        'id': 'product_1',
        'image': 'shoe.png',
        'title': 'Running Shoe',
        'brand': 'Yalla',
        'variants': [
          {
            'id': 23,
            'price': '980.00',
            'sku': 'SEED-08-1',
            'attribute_values': {'size': 'Medium'},
          },
          {'id': 24, 'price': '1100.00'},
        ],
      });

      expect(product.price, '980.00 ~ 1100.00');
      expect(product.variants, hasLength(2));
      expect(product.defaultVariantId, '23');
      expect(product.defaultVariantPrice, '980.00');
      expect(product.code, isNull);
      expect(product.variants.first.attributeValues['size'], 'Medium');
      expect(product.toJson()['variants'], isA<List>());
    });

    test('parses theme, popularity, and product-owned attributes', () {
      final product = ProductData.fromJson({
        'id': 7,
        'name': 'Shoe',
        'theme': 'clothing',
        'is_popular': true,
        'attributes': [
          {
            'id': 1,
            'name': 'النوع',
            'options': [
              {'id': 2, 'value': 'رجالي'},
            ],
          },
        ],
      });

      expect(product.theme, 'clothing');
      expect(product.isPopular, isTrue);
      expect(product.attributes.single.name, 'النوع');
      expect(product.attributes.single.options.single.value, 'رجالي');
    });

    test('parses flat Django product detail variant attributes', () {
      final variant = ProductVariantData.fromJson({
        'id': 14,
        'price': '735.00',
        'sku': 'SEED-07-2',
        'attribute_values': [
          {
            'id': 2,
            'attribute_id': 4,
            'attribute_name': 'الحصة',
            'option_id': 8,
            'option_value': 'عائلية',
          },
        ],
      });

      expect(variant.attributeValues, {'الحصة': 'عائلية'});
    });

    test('parses nested Django variant attribute_values lists', () {
      final variant = ProductVariantData.fromJson({
        'id': 14,
        'price': '735.00',
        'sku': 'SEED-07-2',
        'attribute_values': [
          {
            'id': 2,
            'attribute': {'id': 4, 'name': 'الحصة'},
            'option': {'id': 8, 'value': 'عائلية'},
          },
        ],
      });

      expect(variant.attributeValues, {'الحصة': 'عائلية'});
    });

    test('parses camelCase variant attribute keys', () {
      final variant = ProductVariantData.fromJson({
        'id': 14,
        'price': '735.00',
        'attributeValues': [
          {'attributeName': 'الحجم', 'optionValue': '1 لتر'},
        ],
      });

      expect(variant.attributeValues, {'الحجم': '1 لتر'});
    });

    test('ignores invalid variant attributes safely', () {
      final variant = ProductVariantData.fromJson({
        'id': 14,
        'price': '735.00',
        'attribute_values': [
          null,
          {'attribute': null, 'option': null},
          {
            'attribute': {'name': ''},
            'option': {'value': 'عائلية'},
          },
          {'attribute_name': '', 'option_value': 'عائلية'},
          {'attribute_name': 'الحصة', 'option_value': ''},
        ],
      });

      expect(variant.attributeValues, isEmpty);
    });

    test('ignores missing flat attribute names', () {
      final variant = ProductVariantData.fromJson({
        'id': 14,
        'price': '735.00',
        'attribute_values': [
          {'option_value': 'عائلية'},
        ],
      });

      expect(variant.attributeValues, isEmpty);
    });

    test('ignores missing flat option values', () {
      final variant = ProductVariantData.fromJson({
        'id': 14,
        'price': '735.00',
        'attribute_values': [
          {'attribute_name': 'الحصة'},
        ],
      });

      expect(variant.attributeValues, isEmpty);
    });

    test('parses description and availability from API payloads', () {
      final product = ProductData.fromJson({
        'id': 7,
        'name': 'شوربة خضار',
        'description': 'منتج تجريبي: شوربة خضار.',
        'is_available': false,
        'image': 'soup.png',
      });

      expect(product.description, 'منتج تجريبي: شوربة خضار.');
      expect(product.isAvailable, isFalse);
      expect(product.toJson()['description'], 'منتج تجريبي: شوربة خضار.');
      expect(product.toJson()['isAvailable'], isFalse);
    });

    test('defaults availability to true for older payloads', () {
      final product = ProductData.fromJson({
        'id': 7,
        'name': 'شوربة خضار',
        'image': 'soup.png',
      });

      expect(product.isAvailable, isTrue);
    });
  });
}
