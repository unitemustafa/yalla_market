import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/domain/media_focal_point.dart';

void main() {
  test('normalizes valid focal points and rejects malformed coordinates', () {
    final focal = MediaFocalPoint.fromJson({'x': '1.2', 'y': -2});
    expect(focal.x, 1);
    expect(focal.y, 0);

    final fallback = MediaFocalPoint.fromJson({'x': 'bad', 'y': 0.4});
    expect(fallback.x, MediaFocalPoint.center.x);
    expect(fallback.y, MediaFocalPoint.center.y);
  });
}
