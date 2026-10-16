import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_colors.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brand_store_sections.dart';

void main() {
  testWidgets(
    'Given a static storefront painter when a rail selection animates then it is not repainted',
    (tester) async {
      final selected = ValueNotifier<String?>('first');
      final counter = _PaintCounter();
      addTearDown(selected.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<String?>(
              valueListenable: selected,
              builder: (_, selectedId, _) => CustomPaint(
                painter: counter,
                child: StoreSubcategoryRail(
                  categories: _categories,
                  selectedId: selectedId,
                  languageCode: 'en',
                  categoryDescription: 'A static description',
                  onSelected: (value) => selected.value = value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final initialPaints = counter.paints;

      await tester.tap(find.byKey(const ValueKey('store_subcategory_second')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 60));

      expect(selected.value, 'second');
      expect(counter.paints, initialPaints);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Given a dark RTL rail when it is selected then semantics callback and selected styling are preserved',
    (tester) async {
      final handle = tester.ensureSemantics();
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: StoreSubcategoryRail(
                categories: _categories,
                selectedId: 'first',
                languageCode: 'en',
                categoryDescription: null,
                onSelected: (value) => selected = value,
              ),
            ),
          ),
        ),
      );

      final rail = find.byKey(const ValueKey('store_subcategory_rail'));
      expect(Directionality.of(tester.element(rail)), TextDirection.rtl);
      expect(
        tester.getSemantics(
          find.byKey(const ValueKey('store_subcategory_second')),
        ),
        matchesSemantics(
          label: 'الثاني',
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      final selectedTile = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byKey(const ValueKey('store_subcategory_first')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final border = (selectedTile.decoration! as BoxDecoration).border!;
      expect((border as Border).bottom.color, AppColors.primary);

      final selectedTextStyle = tester.widget<AnimatedDefaultTextStyle>(
        find.descendant(
          of: find.byKey(const ValueKey('store_subcategory_first')),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
      );
      expect(selectedTextStyle.style.fontWeight, FontWeight.w800);
      expect(selectedTextStyle.style.color, AppColors.primary);

      await tester.tap(find.byKey(const ValueKey('store_subcategory_second')));
      expect(selected, 'second');
      handle.dispose();
    },
  );
}

const _categories = [
  StoreSubcategoryData(id: 'first', nameAr: 'الأول', nameEn: 'First'),
  StoreSubcategoryData(id: 'second', nameAr: 'الثاني', nameEn: 'Second'),
];

class _PaintCounter extends CustomPainter {
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paints++;
  }

  @override
  bool shouldRepaint(_PaintCounter oldDelegate) => false;
}
