import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/cloudinary_image_url.dart';

void main() {
  group('optimizedCloudinaryImageUrl', () {
    test('adds automatic format, quality, and a responsive width bucket', () {
      const source =
          'https://res.cloudinary.com/demo/image/upload/v1/products/item.jpg';

      final result = optimizedCloudinaryImageUrl(source, targetWidth: 321);

      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/'
        'f_auto,q_auto,c_limit,w_384/v1/products/item.jpg',
      );
    });

    test('keeps query parameters while optimizing delivery', () {
      const source =
          'https://res.cloudinary.com/demo/image/upload/products/item.png?x=1';

      final result = optimizedCloudinaryImageUrl(source);

      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/'
        'f_auto,q_auto/products/item.png?x=1',
      );
    });

    test('does not modify non-Cloudinary image URLs', () {
      const source = 'https://example.com/products/item.jpg';

      expect(optimizedCloudinaryImageUrl(source, targetWidth: 320), source);
    });

    test('does not stack the same optimization twice', () {
      const source =
          'https://res.cloudinary.com/demo/image/upload/'
          'f_auto,q_auto,c_limit,w_384/v1/products/item.jpg';

      expect(optimizedCloudinaryImageUrl(source, targetWidth: 640), source);
    });
  });
}
