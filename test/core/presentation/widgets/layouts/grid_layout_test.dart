import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/layouts/grid_layout.dart';

void main() {
  const cases = <({double width, int columns})>[
    (width: 250, columns: 2),
    (width: 320, columns: 3),
    (width: 600, columns: 6),
  ];

  for (final testCase in cases) {
    testWidgets(
      'grid uses ${testCase.columns} columns at ${testCase.width}px',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: testCase.width,
                child: GridLayout(
                  itemCount: 6,
                  itemBuilder: (_, index) => ColoredBox(
                    key: ValueKey('item_$index'),
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        );

        final grid = tester.widget<GridView>(find.byType(GridView));
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, testCase.columns);
        expect(tester.takeException(), isNull);
      },
    );
  }

  const categoryCases = <({double width, int columns})>[
    (width: 288, columns: 1),
    (width: 328, columns: 2),
    (width: 568, columns: 3),
  ];

  for (final testCase in categoryCases) {
    testWidgets('category grid keeps readable cards at ${testCase.width}px', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: testCase.width,
              child: GridLayout(
                itemCount: 6,
                minimumCardWidth: 150,
                minCrossAxisCount: 1,
                maxCrossAxisCount: 4,
                itemBuilder: (_, index) => ColoredBox(
                  key: ValueKey('category_$index'),
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, testCase.columns);
      expect(tester.takeException(), isNull);
    });
  }
}
