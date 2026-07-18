import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/features/auth/presentation/views/reset_password_view.dart';
import 'package:yalla_market/features/auth/presentation/widgets/auth_top_bar.dart';

void main() {
  testWidgets('reset password is fixed and uses the signup back button', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(320, 480), Size(360, 600), Size(600, 900)]) {
      await tester.binding.setSurfaceSize(size);
      final textScale = size.height == 480 ? 1.5 : 1.0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const ResetPasswordView(email: 'manual@example.com'),
        ),
      );
      await tester.pump();

      final fixedScroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('fixed_auth_page_scroll')),
      );
      expect(
        fixedScroll.physics,
        size.height < 650
            ? isA<ClampingScrollPhysics>()
            : isA<NeverScrollableScrollPhysics>(),
      );
      final topBar = tester.widget<AuthTopBar>(find.byType(AuthTopBar));
      expect(topBar.showBack, isTrue);
      expect(topBar.showClose, isFalse);
      final artwork = tester.widget<Container>(
        find.byKey(const ValueKey('auth_lock_artwork')),
      );
      expect(artwork.constraints?.maxWidth, 58);
      expect(artwork.constraints?.maxHeight, 58);
      expect(
        find.byKey(const ValueKey('reset_password_email_badge')),
        findsOneWidget,
      );
      expect(find.text('manual@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('reset password scrolls when the keyboard is visible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(430, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: ResetPasswordView(email: 'manual@example.com')),
    );
    expect(
      tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('fixed_auth_page_scroll')),
          )
          .physics,
      isA<NeverScrollableScrollPhysics>(),
    );

    await tester.showKeyboard(find.byType(TextFormField).first);
    await tester.pump();
    final editableFinder = find.byType(EditableText).first;
    final focusNode = tester.widget<EditableText>(editableFinder).focusNode;
    expect(focusNode.hasFocus, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    final keyboardScroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('fixed_auth_page_scroll')),
    );
    expect(keyboardScroll.physics, isA<ClampingScrollPhysics>());
    expect(
      keyboardScroll.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.manual,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AuthTopBar)),
      kind: PointerDeviceKind.unknown,
    );
    await gesture.moveBy(const Offset(0, -100));
    await gesture.up();
    await tester.pump();
    expect(
      tester.widget<EditableText>(editableFinder).focusNode,
      same(focusNode),
    );
    expect(focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset password respects iPhone safe areas and orientations', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetPadding);

    const cases = <({Size size, FakeViewPadding padding, bool scrolls})>[
      (size: Size(320, 568), padding: FakeViewPadding(top: 20), scrolls: true),
      (
        size: Size(390, 844),
        padding: FakeViewPadding(top: 47, bottom: 34),
        scrolls: false,
      ),
      (
        size: Size(430, 932),
        padding: FakeViewPadding(top: 59, bottom: 34),
        scrolls: false,
      ),
      (
        size: Size(844, 390),
        padding: FakeViewPadding(left: 47, right: 47, bottom: 21),
        scrolls: true,
      ),
    ];

    for (final testCase in cases) {
      await tester.binding.setSurfaceSize(testCase.size);
      tester.view.padding = testCase.padding;
      await tester.pumpWidget(
        const MaterialApp(home: ResetPasswordView(email: 'manual@example.com')),
      );
      await tester.pump();

      final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('fixed_auth_page_scroll')),
      );
      expect(
        scroll.physics,
        testCase.scrolls
            ? isA<ClampingScrollPhysics>()
            : isA<NeverScrollableScrollPhysics>(),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
