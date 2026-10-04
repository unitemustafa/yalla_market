import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/states/app_skeleton.dart';

void main() {
  testWidgets(
    'Given a list skeleton, when built, then it creates one placeholder per requested row',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppSkeletonList(rows: 4))),
      );

      expect(find.byType(SkeletonBox), findsNWidgets(4));
    },
  );

  testWidgets(
    'Given initial loading, when data arrives, then it crossfades to content',
    (tester) async {
      final loading = ValueNotifier(true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: loading,
              builder: (context, isLoading, _) => AppLoadingTransition(
                isLoading: isLoading,
                loading: const Text('loading'),
                child: const Text('loaded content'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('loading'), findsOneWidget);

      loading.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('loaded content'), findsOneWidget);
      expect(find.text('loading'), findsNothing);
      loading.dispose();
    },
  );

  testWidgets(
    'Given animations are disabled, when loading changes, then content is available without waiting for a shimmer frame',
    (tester) async {
      final loading = ValueNotifier(true);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: loading,
                builder: (context, isLoading, _) => AppLoadingTransition(
                  isLoading: isLoading,
                  loading: const Text('loading'),
                  child: const Text('loaded content'),
                ),
              ),
            ),
          ),
        ),
      );
      loading.value = false;
      await tester.pump();

      expect(find.text('loaded content'), findsOneWidget);
      expect(find.text('loading'), findsNothing);
      loading.dispose();
    },
  );

  testWidgets(
    'Given a skeleton is removed while tickers are disabled, then it disposes cleanly',
    (tester) async {
      await tester.pumpWidget(
        const TickerMode(
          enabled: false,
          child: MaterialApp(
            home: Scaffold(body: AppSkeleton(child: SkeletonBox(height: 40))),
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('image skeleton reserves explicit and bounded image slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppImageSkeleton(
                key: ValueKey('explicit'),
                width: 64,
                height: 40,
              ),
              SizedBox(
                width: 120,
                height: 72,
                child: AppImageSkeleton(key: ValueKey('bounded')),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('explicit'))),
      const Size(64, 40),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('bounded'))),
      const Size(120, 72),
    );
  });

  testWidgets('loading placeholder is a compact shimmer bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppLoadingPlaceholder())),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SkeletonBox), findsOneWidget);
    expect(tester.getSize(find.byType(SkeletonBox)), const Size(48, 8));
  });
}
