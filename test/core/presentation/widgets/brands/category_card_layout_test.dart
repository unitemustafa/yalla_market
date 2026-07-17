import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/presentation/widgets/brands/brand_card.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:yalla_market/features/home/presentation/widgets/home_categories.dart';
import 'package:yalla_market/features/store/domain/entities/category_data.dart';

void main() {
  testWidgets('featured category card fits Arabic content without overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 156,
              height: 92,
              child: BrandCard(
                showBorder: true,
                brand: 'فئة عادية طويلة',
                productCount: '12 منتج',
                logo: AppAssets.defaultProduct,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppImage)), const Size(56, 56));
  });

  testWidgets('popular category gives the image a clear visible area', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        home: Scaffold(
          body: HomeCategories(
            categories: [
              CategoryData(
                id: '1',
                name: 'فئة والله',
                slug: 'category',
                productCount: 2,
                image: AppAssets.defaultProduct,
                galleryImages: [],
                accentColorValue: 0xFF4F60F6,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppImage)), const Size(58, 38));
  });

  testWidgets('four popular categories fit fully on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: HomeCategories(
              categories: List.generate(
                6,
                (index) => CategoryData(
                  id: '$index',
                  name: 'Category $index',
                  slug: 'category-$index',
                  productCount: index + 1,
                  image: AppAssets.defaultProduct,
                  galleryImages: const [],
                  accentColorValue: 0xFF4F60F6,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    for (var index = 0; index < 4; index++) {
      final finder = find.byKey(ValueKey('home_category_$index'));
      expect(finder, findsOneWidget);
      final rect = tester.getRect(finder);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(320));
    }
    expect(find.byKey(const ValueKey('home_category_4')), findsNothing);
  });
}
