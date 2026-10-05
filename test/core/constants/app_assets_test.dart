import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';

void main() {
  test('full-resolution onboarding posters stay bundled as WebP', () {
    const onboardingAssets = [
      AppAssets.onboardingProducts,
      AppAssets.onboardingCashOnDelivery,
      AppAssets.onboardingFastDelivery,
    ];

    var totalBytes = 0;
    for (final assetPath in onboardingAssets) {
      expect(assetPath, endsWith('.webp'));
      final asset = File(assetPath);
      expect(asset.existsSync(), isTrue, reason: 'Missing $assetPath');
      totalBytes += asset.lengthSync();
    }

    expect(
      totalBytes,
      lessThan(5 * 1024 * 1024),
      reason: 'Lossless onboarding posters should remain below 5 MiB in total.',
    );
  });
}
