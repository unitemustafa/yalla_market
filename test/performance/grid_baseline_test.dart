import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/layouts/grid_layout.dart';

void main() {
  testWidgets(
    'compares nested grid baseline with lazy grid at the same viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var baselineBuilt = 0;
      var lazyBuilt = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GridLayout(
                itemCount: 1000,
                maxCrossAxisCount: 2,
                itemBuilder: (_, index) {
                  baselineBuilt++;
                  return Text('Item $index');
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverGridLayout(
                  itemCount: 1000,
                  maxCrossAxisCount: 2,
                  itemBuilder: (_, index) {
                    lazyBuilt++;
                    return Text('Item $index');
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(baselineBuilt, 1000);
      expect(lazyBuilt, inInclusiveRange(1, 20));
      // Structural counts only; these are not fps measurements.
      // ignore: avoid_print
      print(
        jsonEncode({
          'items': 1000,
          'baseline_built': baselineBuilt,
          'lazy_built': lazyBuilt,
        }),
      );
    },
  );
}
