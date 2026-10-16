import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/layouts/grid_layout.dart';

void main() {
  for (final count in [100, 1000, 10000]) {
    testWidgets('virtualizes $count grid children and reaches the last child', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              controller: controller,
              slivers: [
                SliverGridLayout(
                  itemCount: count,
                  mainAxisExtent: 80,
                  itemBuilder: (_, index) {
                    builds += 1;
                    return SizedBox(key: ValueKey('grid_$index'));
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // The framework retains a cache extent, but it must not build the full
      // 100-item page (and remains bounded for larger catalogs).
      expect(builds, lessThan(60));
      expect(find.byKey(const ValueKey('grid_0')), findsOneWidget);

      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();

      expect(find.byKey(ValueKey('grid_${count - 1}')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'does not rebuild visible children for a scroll that stays in the same row',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              controller: controller,
              slivers: [
                SliverGridLayout(
                  itemCount: 1000,
                  mainAxisExtent: 80,
                  itemBuilder: (_, index) {
                    builds += 1;
                    return SizedBox(key: ValueKey('stable_$index'));
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      final initialBuilds = builds;

      controller.jumpTo(1);
      await tester.pump();

      expect(builds, initialBuilds);
      expect(find.byKey(const ValueKey('stable_0')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
