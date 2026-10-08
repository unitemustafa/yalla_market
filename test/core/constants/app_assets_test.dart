import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';

void main() {
  test(
    'full-resolution onboarding posters stay within the WebP size budget',
    () {
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
        lessThan(1200 * 1024),
        reason:
            'Optimized onboarding posters should remain below 1200 KiB total.',
      );
    },
  );

  test('splash logo stays bundled within the lossless WebP size budget', () {
    expect(AppAssets.splashBrandLogo, endsWith('.webp'));
    final asset = File(AppAssets.splashBrandLogo);
    expect(asset.existsSync(), isTrue);
    expect(asset.lengthSync(), lessThan(300 * 1024));
  });
}
