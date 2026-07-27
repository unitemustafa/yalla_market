import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/config/maptiler_map_config.dart';

void main() {
  test('builds standard MapTiler Streets raster URL', () {
    final url = MapTilerMapConfig.tileUrl(highDensity: false);

    expect(url, contains('/maps/streets-v2/256/{z}/{x}/{y}.png?key='));
    expect(url, isNot(contains('@2x')));
  });

  test('builds high-density MapTiler Streets raster URL', () {
    final url = MapTilerMapConfig.tileUrl(highDensity: true);

    expect(url, contains('/maps/streets-v2/256/{z}/{x}/{y}@2x.png?key='));
  });
}
