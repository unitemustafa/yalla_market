import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/offers/domain/entities/offer_data.dart';

void main() {
  test('offer parses the saved crop and centers legacy or invalid values', () {
    final offer = OfferData.fromJson({
      'image_focus': {'x': 0.25, 'y': 0.75},
    });
    expect(offer.imageFocus.x, 0.25);
    expect(offer.imageFocus.y, 0.75);
    for (final value in [
      null,
      {},
      {'x': double.nan, 'y': 0.5},
    ]) {
      final legacy = OfferData.fromJson({'image_focus': value});
      expect(legacy.imageFocus.x, 0.5);
      expect(legacy.imageFocus.y, 0.5);
    }
  });
}
