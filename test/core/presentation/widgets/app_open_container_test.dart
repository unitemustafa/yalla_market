import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/app_open_container.dart';
import 'package:yalla_market/core/presentation/widgets/refresh_on_return.dart';

void main() {
  testWidgets('does not rebuild destination on each transition frame', (
    tester,
  ) async {
    var builds = 0;
    await _pumpContainer(
      tester,
      openBuilder: (context) {
        builds++;
        return const Scaffold(body: Text('Destination'));
      },
    );

    await tester.tap(find.byKey(const ValueKey('open-card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final initialBuilds = builds;
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(initialBuilds, greaterThan(0));
    expect(builds, initialBuilds);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'builds destination only after the card opens and preserves settings',
    (tester) async {
      final observer = _RouteObserver();
      var destinationBuilds = 0;
      var beforeOpenCalls = 0;

      await _pumpContainer(
        tester,
        observer: observer,
        beforeOpen: () => beforeOpenCalls++,
        openBuilder: (context) {
          destinationBuilds++;
          return Scaffold(
            body: Center(
              child: TextButton(
                key: const ValueKey('close-destination'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Destination'),
              ),
            ),
          );
        },
      );

      expect(destinationBuilds, 0);
      expect(beforeOpenCalls, 0);

      await tester.tap(find.byKey(const ValueKey('open-card')));
      await tester.pumpAndSettle();

      // The destination can rebuild while the container transition settles.
      expect(destinationBuilds, greaterThan(0));
      expect(beforeOpenCalls, 1);
      expect(find.text('Destination'), findsOneWidget);
      expect(observer.pushed.single.settings.name, 'catalog/detail');
      expect(observer.pushed.single.settings.arguments, 'product-42');
    },
  );

  testWidgets('returns to the original card after the destination is popped', (
    tester,
  ) async {
    await _pumpContainer(tester);

    await tester.tap(find.byKey(const ValueKey('open-card')));
    await tester.pumpAndSettle();
    expect(find.text('Destination'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('close-destination')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('open-card')), findsOneWidget);
    expect(find.text('Destination'), findsNothing);
  });

  testWidgets('does not push another destination while opening', (
    tester,
  ) async {
    final observer = _RouteObserver();
    var beforeOpenCalls = 0;
    await _pumpContainer(
      tester,
      observer: observer,
      beforeOpen: () => beforeOpenCalls++,
      opensTwice: true,
    );

    await tester.tap(find.byKey(const ValueKey('open-card')));
    await tester.pumpAndSettle();

    expect(beforeOpenCalls, 1);
    expect(observer.pushed, hasLength(1));
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'iOS edge swipe returns to the card and permits reopening ($direction)',
      (tester) async {
        final observer = _RouteObserver();
        var beforeOpenCalls = 0;
        await _pumpContainer(
          tester,
          observer: observer,
          beforeOpen: () => beforeOpenCalls++,
          opensTwice: true,
          textDirection: direction,
        );
        await tester.tap(find.byKey(const ValueKey('open-card')));
        await tester.pumpAndSettle();
        expect(observer.pushed, hasLength(1));
        expect(observer.pushed.single.settings.name, 'catalog/detail');
        expect(observer.pushed.single.settings.arguments, 'product-42');
        expect(beforeOpenCalls, 1);
        expect(find.byType(BackButton), findsNothing);

        final rtl = direction == TextDirection.rtl;
        await tester.dragFrom(
          Offset(rtl ? 799 : 1, 300),
          Offset(rtl ? -700 : 700, 0),
        );
        await tester.pumpAndSettle();
        expect(find.text('Destination'), findsNothing);
        expect(find.byKey(const ValueKey('open-card')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('open-card')));
        await tester.pumpAndSettle();
        expect(find.text('Destination'), findsOneWidget);
        expect(beforeOpenCalls, 2);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  testWidgets('iOS nested actions do not open the destination', (tester) async {
    final observer = _RouteObserver();
    var actionCalls = 0;
    await _pumpContainer(
      tester,
      observer: observer,
      nestedAction: () => actionCalls++,
    );
    await tester.tap(find.byKey(const ValueKey('nested-action')));
    await tester.pumpAndSettle();
    expect(actionCalls, 1);
    expect(observer.pushed, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('does not open when a nested action is tapped', (tester) async {
    final observer = _RouteObserver();
    var actionCalls = 0;
    await _pumpContainer(
      tester,
      observer: observer,
      nestedAction: () => actionCalls++,
    );

    await tester.tap(find.byKey(const ValueKey('nested-action')));
    await tester.pumpAndSettle();

    expect(actionCalls, 1);
    expect(observer.pushed, isEmpty);
    expect(find.byKey(const ValueKey('open-card')), findsOneWidget);
  });

  testWidgets('uses no transition duration when animations are disabled', (
    tester,
  ) async {
    final observer = _RouteObserver();
    await _pumpContainer(tester, observer: observer, disableAnimations: true);

    await tester.tap(find.byKey(const ValueKey('open-card')));
    await tester.pump();
    final route = observer.pushed.single as PageRoute<void>;
    expect(route.transitionDuration, Duration.zero);
    expect(route.reverseTransitionDuration, Duration.zero);
    expect(find.text('Destination'), findsOneWidget);
  });

  testWidgets(
    'refreshes the source when the destination returns',
    (tester) async {
      final observer = PageRefreshObserver();
      var refreshes = 0;
      await tester.pumpWidget(
        _RefreshHarness(observer: observer, onRefresh: () => refreshes++),
      );
      await tester.pumpAndSettle();
      final initialRefreshes = refreshes;

      await tester.tap(find.byKey(const ValueKey('refresh-open-card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('refresh-close-destination')));
      await tester.pumpAndSettle();

      expect(refreshes, greaterThan(initialRefreshes));
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'refreshes an open destination after a child page returns',
    (tester) async {
      final observer = PageRefreshObserver();
      var refreshes = 0;
      await tester.pumpWidget(
        _DestinationRefreshHarness(
          observer: observer,
          onRefresh: () => refreshes++,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('destination-refresh-open')));
      await tester.pumpAndSettle();
      final initialRefreshes = refreshes;

      await tester.tap(find.byKey(const ValueKey('destination-push-child')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('destination-pop-child')));
      await tester.pumpAndSettle();

      expect(refreshes, greaterThan(initialRefreshes));
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'does not refresh an open destination after a popup closes',
    (tester) async {
      final observer = PageRefreshObserver();
      var refreshes = 0;
      await tester.pumpWidget(
        _DestinationRefreshHarness(
          observer: observer,
          onRefresh: () => refreshes++,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('destination-refresh-open')));
      await tester.pumpAndSettle();
      final initialRefreshes = refreshes;

      await tester.tap(find.byKey(const ValueKey('destination-show-popup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('destination-close-popup')));
      await tester.pumpAndSettle();

      expect(refreshes, initialRefreshes);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'keeps the active destination when its source rebuilds',
    (tester) async {
      final sourceKey = GlobalKey<_RebuildSourceHarnessState>();
      await tester.pumpWidget(_RebuildSourceHarness(key: sourceKey));

      await tester.tap(find.byKey(const ValueKey('rebuild-source-open')));
      await tester.pumpAndSettle();
      expect(find.text('Original'), findsOneWidget);

      sourceKey.currentState!.replaceSource();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('rebuild-push-child')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('rebuild-pop-child')));
      await tester.pumpAndSettle();

      expect(find.text('Original'), findsOneWidget);
      expect(find.text('Replacement'), findsNothing);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'closes safely after its source is removed while open',
    (tester) async {
      final sourceKey = GlobalKey<_RemovableSourceHarnessState>();
      await tester.pumpWidget(_RemovableSourceHarness(key: sourceKey));

      await tester.tap(find.byKey(const ValueKey('removable-source-open')));
      await tester.pumpAndSettle();
      expect(find.text('Removable destination'), findsOneWidget);

      sourceKey.currentState!.removeSource();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('removable-source-close')));
      await tester.pumpAndSettle();

      expect(find.text('Removable destination'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );
}

Future<void> _pumpContainer(
  WidgetTester tester, {
  NavigatorObserver? observer,
  WidgetBuilder? openBuilder,
  VoidCallback? beforeOpen,
  VoidCallback? nestedAction,
  bool opensTwice = false,
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
}) => tester.pumpWidget(
  MaterialApp(
    navigatorObservers: observer == null ? const [] : [observer],
    builder: (_, child) =>
        Directionality(textDirection: textDirection, child: child!),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 120,
              child: AppOpenContainer(
                routeSettings: const RouteSettings(
                  name: 'catalog/detail',
                  arguments: 'product-42',
                ),
                beforeOpen: beforeOpen,
                openBuilder:
                    openBuilder ??
                    (context) => Scaffold(
                      body: Center(
                        child: TextButton(
                          key: const ValueKey('close-destination'),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Destination'),
                        ),
                      ),
                    ),
                closedBuilder: (context, open) => Material(
                  child: InkWell(
                    key: const ValueKey('open-card'),
                    onTap: () {
                      open();
                      if (opensTwice) open();
                    },
                    child: Center(
                      child: IconButton(
                        key: const ValueKey('nested-action'),
                        onPressed: nestedAction,
                        icon: const Icon(Icons.favorite),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

class _RouteObserver extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name == 'catalog/detail') pushed.add(route);
    super.didPush(route, previousRoute);
  }
}

class _RefreshHarness extends StatefulWidget {
  const _RefreshHarness({required this.observer, required this.onRefresh});

  final PageRefreshObserver observer;
  final VoidCallback onRefresh;

  @override
  State<_RefreshHarness> createState() => _RefreshHarnessState();
}

class _RefreshHarnessState extends State<_RefreshHarness> {
  final _catalogChanges = ValueNotifier<int>(0);

  @override
  void dispose() {
    _catalogChanges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorObservers: [widget.observer],
    builder: (context, child) => PageRefreshScope(
      observer: widget.observer,
      catalogChanges: _catalogChanges,
      child: child!,
    ),
    home: RefreshOnReturn(
      onRefresh: () async => widget.onRefresh(),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 180,
            height: 120,
            child: AppOpenContainer(
              routeSettings: const RouteSettings(name: 'catalog/detail'),
              openBuilder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    key: const ValueKey('refresh-close-destination'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Destination'),
                  ),
                ),
              ),
              closedBuilder: (context, open) => Material(
                child: InkWell(
                  key: const ValueKey('refresh-open-card'),
                  onTap: open,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DestinationRefreshHarness extends StatefulWidget {
  const _DestinationRefreshHarness({
    required this.observer,
    required this.onRefresh,
  });

  final PageRefreshObserver observer;
  final VoidCallback onRefresh;

  @override
  State<_DestinationRefreshHarness> createState() =>
      _DestinationRefreshHarnessState();
}

class _DestinationRefreshHarnessState
    extends State<_DestinationRefreshHarness> {
  final _catalogChanges = ValueNotifier<int>(0);

  @override
  void dispose() {
    _catalogChanges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorObservers: [widget.observer],
    builder: (context, child) => PageRefreshScope(
      observer: widget.observer,
      catalogChanges: _catalogChanges,
      child: child!,
    ),
    home: Scaffold(
      body: AppOpenContainer(
        routeSettings: const RouteSettings(name: 'catalog/detail'),
        closedBuilder: (context, open) => InkWell(
          key: const ValueKey('destination-refresh-open'),
          onTap: open,
          child: const SizedBox.expand(),
        ),
        openBuilder: (context) => RefreshOnReturn(
          onRefresh: () async => widget.onRefresh(),
          child: Scaffold(
            body: Column(
              children: [
                TextButton(
                  key: const ValueKey('destination-push-child'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => Scaffold(
                        body: TextButton(
                          key: const ValueKey('destination-pop-child'),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Child'),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Push child'),
                ),
                TextButton(
                  key: const ValueKey('destination-show-popup'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: TextButton(
                        key: const ValueKey('destination-close-popup'),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close popup'),
                      ),
                    ),
                  ),
                  child: const Text('Show popup'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RebuildSourceHarness extends StatefulWidget {
  const _RebuildSourceHarness({super.key});

  @override
  State<_RebuildSourceHarness> createState() => _RebuildSourceHarnessState();
}

class _RebuildSourceHarnessState extends State<_RebuildSourceHarness> {
  var _destinationLabel = 'Original';

  void replaceSource() => setState(() => _destinationLabel = 'Replacement');

  @override
  Widget build(BuildContext context) {
    final destinationLabel = _destinationLabel;
    return MaterialApp(
      home: Scaffold(
        body: AppOpenContainer(
          routeSettings: RouteSettings(arguments: destinationLabel),
          closedBuilder: (context, open) => InkWell(
            key: const ValueKey('rebuild-source-open'),
            onTap: open,
            child: const SizedBox.expand(),
          ),
          openBuilder: (context) => Scaffold(
            body: Column(
              children: [
                Text(destinationLabel),
                TextButton(
                  key: const ValueKey('rebuild-push-child'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => Scaffold(
                        body: TextButton(
                          key: const ValueKey('rebuild-pop-child'),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Child'),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Push child'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RemovableSourceHarness extends StatefulWidget {
  const _RemovableSourceHarness({super.key});

  @override
  State<_RemovableSourceHarness> createState() =>
      _RemovableSourceHarnessState();
}

class _RemovableSourceHarnessState extends State<_RemovableSourceHarness> {
  var _showSource = true;

  void removeSource() => setState(() => _showSource = false);

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: _showSource
          ? AppOpenContainer(
              routeSettings: const RouteSettings(name: 'catalog/detail'),
              closedBuilder: (context, open) => InkWell(
                key: const ValueKey('removable-source-open'),
                onTap: open,
                child: const SizedBox.expand(),
              ),
              openBuilder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    key: const ValueKey('removable-source-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Removable destination'),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    ),
  );
}
