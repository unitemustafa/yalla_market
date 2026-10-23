import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/actions/copy_content_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );

  Future<void> pumpAction(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => copyContentLink(
              context: context,
              link: 'https://example.com/share/products/42/?variant=202',
              successTitle: 'Product link copied',
            ),
            child: const Text('Copy'),
          ),
        ),
      ),
    ),
  );

  testWidgets('reports success only after the link has been copied', (
    tester,
  ) async {
    String? copied;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    await pumpAction(tester);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copied, 'https://example.com/share/products/42/?variant=202');
    expect(find.text('Product link copied'), findsOneWidget);
  });

  testWidgets('clipboard failure shows an error instead of success', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'clipboard_unavailable');
      }
      return null;
    });
    await pumpAction(tester);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(find.text('Could not copy link'), findsOneWidget);
    expect(find.text('Product link copied'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final fails in [false, true]) {
    testWidgets(
      'finishing after the page is disposed is safe (fails: $fails)',
      (tester) async {
        final pending = Completer<void>();
        messenger.setMockMethodCallHandler(SystemChannels.platform, (
          call,
        ) async {
          if (call.method == 'Clipboard.setData') {
            await pending.future;
            if (fails) throw PlatformException(code: 'clipboard_unavailable');
          }
          return null;
        });
        await pumpAction(tester);
        await tester.tap(find.text('Copy'));
        await tester.pumpWidget(const SizedBox.shrink());
        pending.complete();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
