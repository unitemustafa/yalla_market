import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/presentation/views/orders/widgets/custom_date_range_sheet.dart';

void main() {
  testWidgets('clamps the initial range and returns the visible selection', (
    tester,
  ) async {
    DateTimeRange? result;
    final firstDate = DateTime(2025, 1, 10);
    final lastDate = DateTime(2025, 1, 20);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<DateTimeRange>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CustomDateRangeSheet(
                    firstDate: firstDate,
                    lastDate: lastDate,
                    initialRange: DateTimeRange(
                      start: DateTime(2025, 1, 1, 18),
                      end: DateTime(2025, 1, 31, 9),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('10/01/2025'), findsOneWidget);
    expect(find.text('20/01/2025'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(result?.start, firstDate);
    expect(result?.end, lastDate);
  });

  testWidgets('opens and cancels the wheel picker without changing the range', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showModalBottomSheet<DateTimeRange>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CustomDateRangeSheet(
                  firstDate: DateTime(2025, 1, 1),
                  lastDate: DateTime(2025, 12, 31),
                  initialRange: DateTimeRange(
                    start: DateTime(2025, 3, 4),
                    end: DateTime(2025, 3, 8),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('04/03/2025'));
    await tester.pumpAndSettle();
    expect(find.text('Choose date'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('04/03/2025'), findsOneWidget);
    expect(find.text('08/03/2025'), findsOneWidget);
  });
}
