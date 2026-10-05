import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/constants/app_colors.dart';
import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:yalla_market/core/presentation/widgets/brands/brand_card.dart';
import 'package:yalla_market/core/presentation/widgets/brands/category_tile.dart';
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
    expect(tester.getSize(find.byType(AppImage)), const Size(56, 56));
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
    expect(tester.takeException(), isNull);
  });

  for (final direction in TextDirection.values) {
    for (final count in [1, 2, 4]) {
      testWidgets(
        'category cards keep four slots for $count items in $direction',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(360, 240));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Directionality(
                  textDirection: direction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: HomeCategories(
                      categories: List.generate(
                        count,
                        (index) => CategoryData(
                          id: '$index',
                          name: 'Category $index',
                          slug: '$index',
                          productCount: 1,
                          image: AppAssets.defaultProduct,
                          galleryImages: const [],
                          accentColorValue: 0xFF4F60F6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          for (var index = 0; index < count; index++) {
            final card = find.byKey(ValueKey('home_category_$index'));
            expect(tester.getSize(card), const Size(76, 84));
            final label = find.descendant(
              of: card,
              matching: find.byType(Text),
            );
            expect(
              tester.getRect(card).contains(tester.getRect(label).topLeft),
              isTrue,
            );
            expect(
              tester.getRect(card).contains(tester.getRect(label).bottomRight),
              isTrue,
            );
          }
          if (count > 1) {
            final first = tester.getRect(
              find.byKey(const ValueKey('home_category_0')),
            );
            final second = tester.getRect(
              find.byKey(const ValueKey('home_category_1')),
            );
            final gap = direction == TextDirection.ltr
                ? second.left - first.right
                : first.left - second.right;
            expect(gap, AppCategoryLayout.spacing);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('Arabic names stay inside one rounded card at large text scale', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Center(
                child: SizedBox(
                  width: 66,
                  height: 84,
                  child: CategoryTile(
                    name: 'الصحة والعناية الشخصية',
                    image: AppAssets.defaultProduct,
                    accentColor: Colors.red,
                    onTap: () => taps++,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final card = find.byType(CategoryTile);
    final panel = tester.widget<Material>(
      find.descendant(of: card, matching: find.byType(Material)),
    );
    expect(panel.color, AppColors.categoryCardBackground);
    expect(panel.borderRadius, BorderRadius.circular(12));
    final label = find.text('الصحة والعناية الشخصية');
    expect(tester.widget<Text>(label).maxLines, 1);
    expect(tester.widget<Text>(label).overflow, TextOverflow.ellipsis);
    expect(
      tester.getRect(card).contains(tester.getRect(label).topLeft),
      isTrue,
    );
    expect(
      tester.getRect(card).contains(tester.getRect(label).bottomRight),
      isTrue,
    );
    expect(
      tester.widget<AppImage>(find.byType(AppImage)).role,
      AppImageRole.illustration,
    );
    expect(tester.getSize(find.byType(AppImage)), const Size(56, 56));
    await tester.tap(card);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
