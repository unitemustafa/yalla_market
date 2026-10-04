import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/buttons/app_action_button.dart';
import 'package:yalla_market/core/presentation/widgets/states/app_skeleton.dart';

void main() {
  testWidgets(
    'pending action is disabled, shows a shimmer bar, then becomes actionable again',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppActionButton(
              label: 'Save',
              isLoading: true,
              onPressed: () => calls += 1,
            ),
          ),
        ),
      );

      final pendingButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(pendingButton.onPressed, isNull);
      expect(find.byType(AppLoadingPlaceholder), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppActionButton(label: 'Save', onPressed: () => calls += 1),
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));

      expect(calls, 1);
    },
  );
}
