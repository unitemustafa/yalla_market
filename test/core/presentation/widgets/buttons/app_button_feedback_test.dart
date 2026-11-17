import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/buttons/app_action_button.dart';
import 'package:yalla_market/core/presentation/widgets/buttons/app_button_feedback.dart';

void main() {
  final haptics = <MethodCall>[];

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
          return null;
        });
  });

  tearDown(() {
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget action({
    VoidCallback? onPressed,
    bool isLoading = false,
    bool disableAnimations = false,
    AppActionButtonVariant variant = AppActionButtonVariant.filled,
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 240,
            child: AppActionButton(
              label: 'Save',
              onPressed: onPressed,
              isLoading: isLoading,
              variant: variant,
            ),
          ),
        ),
      ),
    ),
  );

  Finder getFeedback() => find.byType(AppButtonFeedback);

  Finder getButton() => find
      .descendant(
        of: getFeedback(),
        matching: find.bySubtype<ButtonStyleButton>(),
      )
      .first;

  Transform feedbackTransform(WidgetTester tester) => tester.widget<Transform>(
    find.descendant(of: getFeedback(), matching: find.byType(Transform)).first,
  );

  double scale(WidgetTester tester) =>
      feedbackTransform(tester).transform.storage[0];

  Future<TestGesture> press(WidgetTester tester) async {
    final gesture = await tester.startGesture(tester.getCenter(getFeedback()));
    await tester.pump(kPressTimeout + const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    return gesture;
  }

  for (final variant in AppActionButtonVariant.values) {
    testWidgets(
      '${variant.name} shrinks, pulses once and restores on release',
      (tester) async {
        var calls = 0;
        await tester.pumpWidget(
          action(variant: variant, onPressed: () => calls++),
        );
        final size = tester.getSize(getFeedback());
        expect(scale(tester), 1);

        final gesture = await press(tester);
        expect(scale(tester), closeTo(0.96, 0.0001));
        expect(tester.getSize(getFeedback()), size);
        expect(feedbackTransform(tester).transformHitTests, isFalse);
        expect(haptics.single.arguments, 'HapticFeedbackType.lightImpact');
        expect(calls, 0);

        // Rebuild while held: no extra haptic or lost pressed state.
        await tester.pumpWidget(
          action(variant: variant, onPressed: () => calls++),
        );
        expect(scale(tester), closeTo(0.96, 0.0001));
        expect(haptics, hasLength(1));

        await gesture.up();
        expect(calls, 1);
        await tester.pumpAndSettle();
        expect(scale(tester), 1);
        expect(haptics, hasLength(1));

        await tester.tap(getButton());
        expect(calls, 2);
        expect(haptics, hasLength(2));
      },
    );
  }

  testWidgets('cancel restores scale without invoking the action', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(action(onPressed: () => calls++));
    final gesture = await press(tester);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(scale(tester), 1);
    expect(calls, 0);
    expect(haptics, hasLength(1));
  });

  testWidgets('a scroll cancels the press without invoking the action', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              AppActionButton(label: 'Save', onPressed: () => calls++),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      ),
    );
    final gesture = await press(tester);
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(tester), 1);
    expect(calls, 0);
    expect(haptics, hasLength(1));
  });

  for (final loading in [false, true]) {
    testWidgets('disabled button (loading: $loading) has no feedback', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        action(isLoading: loading, onPressed: loading ? () => calls++ : null),
      );
      final gesture = await press(tester);
      await gesture.up();
      expect(scale(tester), 1);
      expect(haptics, isEmpty);
      expect(calls, 0);
    });

    testWidgets('disabling during a press (loading: $loading) resets safely', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(action(onPressed: () => calls++));
      final gesture = await press(tester);
      await tester.pumpWidget(
        action(isLoading: loading, onPressed: loading ? () => calls++ : null),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(scale(tester), 1);
      await gesture.up();
      expect(calls, 0);
      expect(haptics, hasLength(1));
    });
  }

  testWidgets('reduced motion keeps scale at one but still pulses', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      action(disableAnimations: true, onPressed: () => calls++),
    );
    final gesture = await press(tester);
    expect(scale(tester), 1);
    expect(haptics, hasLength(1));
    await gesture.up();
    expect(calls, 1);
  });

  testWidgets('enabling reduced motion while held immediately restores scale', (
    tester,
  ) async {
    await tester.pumpWidget(action(onPressed: () {}));
    final gesture = await press(tester);
    await tester.pumpWidget(action(disableAnimations: true, onPressed: () {}));
    expect(scale(tester), 1);
    expect(haptics, hasLength(1));
    await gesture.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing a pressed button leaves no active ticker', (
    tester,
  ) async {
    await tester.pumpWidget(action(onPressed: () {}));
    final gesture = await press(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await gesture.cancel();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('platform feedback failure does not prevent the action', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            throw PlatformException(code: 'unavailable');
          }
          return null;
        });
    var calls = 0;
    await tester.pumpWidget(action(onPressed: () => calls++));
    await tester.tap(getButton());
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'FilledButton.icon uses the shared feedback without changing its key',
    (tester) async {
      const key = ValueKey('confirm');
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButtonFeedback(
              builder: (_, states) => FilledButton.icon(
                key: key,
                statesController: states,
                onPressed: () => calls++,
                icon: const Icon(Icons.check),
                label: const Text('Confirm'),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(key), findsOneWidget);
      final gesture = await press(tester);
      expect(scale(tester), closeTo(0.96, 0.0001));
      expect(haptics, hasLength(1));
      await gesture.up();
      expect(calls, 1);
    },
  );
}
