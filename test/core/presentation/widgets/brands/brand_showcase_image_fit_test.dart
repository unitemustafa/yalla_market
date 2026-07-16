import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/presentation/widgets/brands/brand_showcase.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';

void main() {
  testWidgets('store and product images fill popular store cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: BrandShowcase(
              brand: 'Store',
              productCount: '2 products',
              logo: AppAssets.defaultStore,
              images: [AppAssets.defaultProduct, AppAssets.defaultProduct],
            ),
          ),
        ),
      ),
    );

    final images = tester.widgetList<AppImage>(find.byType(AppImage));
    expect(images, hasLength(3));
    expect(images.every((image) => image.fit == BoxFit.cover), isTrue);
    expect(tester.takeException(), isNull);
  });
}
