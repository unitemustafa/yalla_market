import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/routing/shared_content_links.dart';

void main() {
  test('parses custom product and offer deep links', () {
    final product = SharedContentDeepLink.tryParse(
      Uri.parse('yallamarket://products/42'),
    );
    final offer = SharedContentDeepLink.tryParse(
      Uri.parse('yallamarket://offers/7'),
    );

    expect(product?.type, SharedContentType.product);
    expect(product?.id, '42');
    expect(offer?.type, SharedContentType.offer);
    expect(offer?.id, '7');
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
