import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/layouts/android_tablet_viewport.dart';

void main() {
  testWidgets('keeps a portrait phone full screen', (tester) async {
    final observed = await _pumpViewport(tester, size: const Size(412, 915));

    expect(
      find.byKey(const ValueKey('android_tablet_letterbox')),
      findsNothing,
    );
    expect(observed.size, const Size(412, 915));
    expect(
      tester.getSize(find.byKey(const ValueKey('viewport_probe'))),
      const Size(412, 915),
    );
  });

  testWidgets('keeps a portrait tablet full screen', (tester) async {
    final observed = await _pumpViewport(tester, size: const Size(800, 1280));

    expect(
      find.byKey(const ValueKey('android_tablet_letterbox')),
      findsNothing,
    );
    expect(observed.size, const Size(800, 1280));
    expect(
      tester.getSize(find.byKey(const ValueKey('viewport_probe'))),
      const Size(800, 1280),
    );
  });

  testWidgets('centers a 3:4 viewport on an Android landscape tablet', (
    tester,
  ) async {
    final observed = await _pumpViewport(
      tester,
      size: const Size(1280, 800),
      padding: const FakeViewPadding(top: 24, bottom: 16),
      viewInsets: const FakeViewPadding(bottom: 280),
    );

    expect(
      find.byKey(const ValueKey('android_tablet_letterbox')),
      findsOneWidget,
    );
    final viewportRect = tester.getRect(
      find.byKey(const ValueKey('android_tablet_viewport')),
    );
    expect(viewportRect, const Rect.fromLTWH(340, 0, 600, 800));
    expect(observed.size, const Size(600, 800));
    expect(observed.padding, const EdgeInsets.only(top: 24, bottom: 16));
    expect(observed.viewInsets.bottom, 280);
  });

  testWidgets('does not letterbox a non-Android landscape tablet', (
    tester,
  ) async {
    final observed = await _pumpViewport(
      tester,
      size: const Size(1280, 800),
      platform: TargetPlatform.iOS,
    );

    expect(
      find.byKey(const ValueKey('android_tablet_letterbox')),
      findsNothing,
    );
    expect(observed.size, const Size(1280, 800));
  });
}

Future<MediaQueryData> _pumpViewport(
  WidgetTester tester, {
  required Size size,
  TargetPlatform platform = TargetPlatform.android,
  FakeViewPadding padding = FakeViewPadding.zero,
  FakeViewPadding viewInsets = FakeViewPadding.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = padding;
  tester.view.viewInsets = viewInsets;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewInsets);

  MediaQueryData? observed;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => AndroidTabletViewport(
        platformOverride: platform,
        child: child ?? const SizedBox.shrink(),
      ),
      home: Builder(
        builder: (context) {
          observed = MediaQuery.of(context);
          return const SizedBox.expand(
            key: ValueKey('viewport_probe'),
            child: ColoredBox(color: Colors.white),
          );
        },
      ),
    ),
  );

  return observed!;
}
