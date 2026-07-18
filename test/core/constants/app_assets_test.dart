import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';

void main() {
  test('onboarding artwork stays optimized as WebP', () {
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
      lessThan(512 * 1024),
      reason: 'Onboarding artwork should remain below 512 KiB in total.',
    );
  });
}
