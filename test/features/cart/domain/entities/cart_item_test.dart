import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';

void main() {
  group('CartItemAttribute', () {
    test('maps to and from json', () {
      const attribute = CartItemAttribute(label: 'Size', value: 'Large');

      expect(attribute.toJson(), {'label': 'Size', 'value': 'Large'});
      expect(
        CartItemAttribute.fromJson({
          'label': 'Color',
          'value': 'Green',
        }).toJson(),
        {'label': 'Color', 'value': 'Green'},
      );
    });
  });

  group('CartItemData', () {
    test('parses API payload variants and normalizes price values', () {
      final item = CartItemData.fromJson({
        'id': 10,
        'product_id': 20,
        'variant_id': 30,
        'market_id': 40,
        'market_name': 'Atlas Market',
        'imageUrl': 'https://cdn.example.com/products/product.png',
        'brand': 'Yalla',
        'name': 'Market basket',
        'unitPrice': 'EGP 1,250.50',
        'quantity': '3',
        'attributes': [
          {'label': 'Size', 'value': 'Medium'},
        ],
      });

      expect(item.id, '10');
      expect(item.productId, '20');
      expect(item.variantId, '30');
      expect(item.marketId, '40');
      expect(item.marketName, 'Atlas Market');
      expect(item.image, 'https://cdn.example.com/products/product.png');
      expect(item.title, 'Market basket');
      expect(item.price, 1250.5);
      expect(item.quantity, 3);
      expect(item.attributes.single.label, 'Size');
    });

    test('falls back to safe defaults for partial payloads', () {
      final item = CartItemData.fromJson({'id': 'cart-1'});

      expect(item.id, 'cart-1');
      expect(item.image, isEmpty);
      expect(item.brand, isEmpty);
      expect(item.title, isEmpty);
      expect(item.price, 0);
      expect(item.quantity, 1);
      expect(item.attributes, isEmpty);
      expect(item.offerProducts, isEmpty);
    });

    test('copyWith updates only provided fields', () {
      const item = CartItemData(
        id: '1',
        productId: 'product-1',
        image: 'old.png',
        brand: 'Old brand',
        title: 'Old title',
        price: 10,
        quantity: 1,
      );

      final updated = item.copyWith(title: 'New title', quantity: 4);

      expect(updated.id, item.id);
      expect(updated.productId, item.productId);
      expect(updated.image, item.image);
      expect(updated.brand, item.brand);
      expect(updated.title, 'New title');
      expect(updated.price, item.price);
      expect(updated.quantity, 4);
    });

    test('serializes all public fields', () {
      const item = CartItemData(
        id: '1',
        productId: 'product-1',
        variantId: 'variant-1',
        marketId: 'market-1',
        marketName: 'Atlas Market',
        image: 'product.png',
        brand: 'Yalla',
        title: 'Market basket',
        price: 12.5,
        quantity: 2,
        attributes: [CartItemAttribute(label: 'Size', value: 'Large')],
      );

      expect(item.toJson(), {
        'id': '1',
        'productId': 'product-1',
        'variantId': 'variant-1',
        'additionIds': <String>[],
        'marketId': 'market-1',
        'marketName': 'Atlas Market',
        'image': 'product.png',
        'brand': 'Yalla',
        'title': 'Market basket',
        'price': 12.5,
        'quantity': 2,
        'attributes': [
          {'label': 'Size', 'value': 'Large'},
        ],
        'itemType': 'product',
        'visibilityMode': 'general',
        'regionSlugs': [],
        'regionNames': [],
        'offerProducts': [],
      });
    });

    test('serializes package products together with the offer cart item', () {
      const item = CartItemData(
        id: 'offer-2',
        image: 'offer.png',
        brand: 'Package offer',
        title: 'Sharm offer',
        price: 78.2,
        quantity: 1,
        itemType: 'offer',
        offerProducts: [
          CartOfferProductData(
            productId: '7',
            variantId: '12',
            image: 'chips.png',
            brand: 'Grocery Store',
            title: 'Chips',
            price: 20,
            quantity: 1,
          ),
          CartOfferProductData(
            productId: '6',
            variantId: '10',
            image: 'harissa.png',
            brand: 'Dessert Store',
            title: 'Harissa',
            price: 72,
            quantity: 1,
          ),
        ],
      );

      final restored = CartItemData.fromJson(item.toJson());

      expect(restored.title, 'Sharm offer');
      expect(restored.offerProducts, hasLength(2));
      expect(restored.offerProducts.map((product) => product.title), [
        'Chips',
        'Harissa',
      ]);
      expect(restored.offerProducts.last.price, 72);
    });
  });
}
