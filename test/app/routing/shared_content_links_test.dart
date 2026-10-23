import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/routing/shared_content_links.dart';

void main() {
  test(
    'selected product variant survives building and parsing a share link',
    () {
      final link = SharedContentLinks.product('42', variantId: '202');
      final target = SharedContentDeepLink.tryParse(Uri.parse(link));
      expect(target?.id, '42');
      expect(target?.variantId, '202');
      expect(target?.type, SharedContentType.product);
    },
  );

  test('HTTPS product links preserve the selected variant', () {
    final target = SharedContentDeepLink.tryParse(
      Uri.parse('https://example.com/share/products/42/?variant=202'),
    );
    expect(target?.variantId, '202');
  });

  test('invalid or ambiguous optional variants still open the product', () {
    for (final query in [
      'variant=0',
      'variant=-1',
      'variant=bad',
      'variant=1&variant=2',
    ]) {
      final target = SharedContentDeepLink.tryParse(
        Uri.parse('yallamarket://products/42?$query'),
      );
      expect(target?.id, '42');
      expect(target?.variantId, isNull);
    }
    expect(
      SharedContentLinks.product('42', variantId: 'bad'),
      SharedContentLinks.product('42'),
    );
    expect(
      SharedContentDeepLink.tryParse(
        Uri.parse('yallamarket://offers/7?variant=202'),
      )?.variantId,
      isNull,
    );
  });

  test('parses custom product, offer, and market deep links', () {
    final product = SharedContentDeepLink.tryParse(
      Uri.parse('yallamarket://products/42'),
    );
    final offer = SharedContentDeepLink.tryParse(
      Uri.parse('yallamarket://offers/7'),
    );
    final market = SharedContentDeepLink.tryParse(
      Uri.parse('yallamarket://markets/9'),
    );

    expect(product?.type, SharedContentType.product);
    expect(product?.id, '42');
    expect(offer?.type, SharedContentType.offer);
    expect(offer?.id, '7');
    expect(market?.type, SharedContentType.market);
    expect(market?.id, '9');
  });

  test('parses public HTTPS share links', () {
    final target = SharedContentDeepLink.tryParse(
      Uri.parse('https://example.com/share/products/13/'),
    );

    expect(target?.type, SharedContentType.product);
    expect(target?.id, '13');
  });

  test('rejects unknown, empty, and non-positive shared content', () {
    expect(
      SharedContentDeepLink.tryParse(
        Uri.parse('yallamarket://products/42?variant=%FF'),
      ),
      isNull,
    );
    expect(
      SharedContentDeepLink.tryParse(Uri.parse('yallamarket://stores/1')),
      isNull,
    );
    expect(
      SharedContentDeepLink.tryParse(Uri.parse('yallamarket://products/0')),
      isNull,
    );
    expect(
      SharedContentDeepLink.tryParse(Uri.parse('yallamarket://offers/nope')),
      isNull,
    );
  });
}
