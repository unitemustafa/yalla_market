import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/app_list_entrance.dart';

void main() {
  testWidgets('staggers six rows and finishes within 550 milliseconds', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _ListPage(ids: ['a', 'b', 'c', 'd', 'e', 'f', 'g']),
      ),
    );
    expect(_opacity(tester, 'a'), 0);
    expect(_opacity(tester, 'b'), 0);
    expect(_opacity(tester, 'g'), 1);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 25));
    expect(_opacity(tester, 'a'), inExclusiveRange(0, 1));
    expect(_opacity(tester, 'b'), 0);
    await tester.pump(const Duration(milliseconds: 75));
    expect(_opacity(tester, 'a'), greaterThan(_opacity(tester, 'b')));
    expect(_opacity(tester, 'b'), greaterThan(0));
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('a')),
        matching: find.byType(Transform),
      ),
    );
    expect(transform.transform.storage[13], inExclusiveRange(0, 12));

    await tester.pump(const Duration(milliseconds: 450));
    for (final id in ['a', 'b', 'c', 'd', 'e', 'f', 'g']) {
      expect(_opacity(tester, id), 1);
    }
  });

  testWidgets('waits for data and does not replay after an empty result', (
    tester,
  ) async {
    final key = GlobalKey<_ListPageState>();
    await tester.pumpWidget(
      MaterialApp(
        home: _ListPage(key: key, ids: const []),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    key.currentState!.show(['a', 'b']);
    await tester.pump();
    expect(_opacity(tester, 'a'), 0);
    await tester.pumpAndSettle();

    key.currentState!.show([]);
    await tester.pump();
    key.currentState!.show(['a', 'new']);
    await tester.pump();
    expect(_opacity(tester, 'a'), 1);
    expect(_opacity(tester, 'new'), 1);
  });

  testWidgets(
    'updates and reordering preserve slots while new rows appear immediately',
    (tester) async {
      final key = GlobalKey<_ListPageState>();
      await tester.pumpWidget(
        MaterialApp(
          home: _ListPage(key: key, ids: const ['a', 'b', 'c']),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final beforeA = _opacity(tester, 'a');
      final beforeB = _opacity(tester, 'b');

      key.currentState!.show(['b', 'new', 'a']);
      await tester.pump();
      expect(_opacity(tester, 'a'), beforeA);
      expect(_opacity(tester, 'b'), beforeB);
      expect(_opacity(tester, 'new'), 1);
      await tester.pumpAndSettle();

      key.currentState!.show(['c', 'b', 'a', 'next-page']);
      await tester.pump();
      for (final id in ['c', 'b', 'a', 'next-page']) {
        expect(_opacity(tester, id), 1);
      }
    },
  );

  testWidgets('scrolling lazy rows out and back does not replay entrance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: _ListPage(
          ids: List.generate(30, (index) => '$index'),
          rowHeight: 100,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1600));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('0')), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(_opacity(tester, '0'), 1);
    expect(_opacity(tester, '1'), 1);
  });

  testWidgets('reduced motion shows rows immediately and never replays', (
    tester,
  ) async {
    final key = GlobalKey<_ListPageState>();
    await tester.pumpWidget(
      MaterialApp(
        home: _ListPage(key: key, ids: const ['a', 'b'], reducedMotion: true),
      ),
    );
    expect(_opacity(tester, 'a'), 1);
    expect(_opacity(tester, 'b'), 1);
    expect(tester.binding.transientCallbackCount, 0);
    key.currentState!.setReducedMotion(false);
    await tester.pump();
    expect(_opacity(tester, 'a'), 1);
  });

  testWidgets('enabling reduced motion during entrance completes all rows', (
    tester,
  ) async {
    final key = GlobalKey<_ListPageState>();
    await tester.pumpWidget(
      MaterialApp(
        home: _ListPage(key: key, ids: const ['a', 'b']),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    key.currentState!.setReducedMotion(true);
    await tester.pump();
    expect(_opacity(tester, 'a'), 1);
    expect(_opacity(tester, 'b'), 1);
    expect(tester.binding.transientCallbackCount, 0);
    key.currentState!.setReducedMotion(false);
    await tester.pump();
    expect(_opacity(tester, 'b'), 1);
  });

  testWidgets('a new page visit animates again and early disposal is safe', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _ListPage(ids: ['a'])));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      const MaterialApp(
        home: _ListPage(key: ValueKey('next-visit'), ids: ['a']),
      ),
    );
    expect(_opacity(tester, 'a'), 0);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}

double _opacity(WidgetTester tester, String id) => tester
    .widget<Opacity>(
      find.descendant(
        of: find.byKey(ValueKey(id)),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;

class _ListPage extends StatefulWidget {
  const _ListPage({
    super.key,
    required this.ids,
    this.reducedMotion = false,
    this.rowHeight = 40,
  });

  final List<String> ids;
  final bool reducedMotion;
  final double rowHeight;

  @override
  State<_ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<_ListPage>
    with SingleTickerProviderStateMixin {
  late final AppListEntranceController _entrance;
  late List<String> _ids = widget.ids;
  late bool _reducedMotion = widget.reducedMotion;

  @override
  void initState() {
    super.initState();
    _entrance = AppListEntranceController(vsync: this);
  }

  void show(List<String> ids) => setState(() => _ids = ids);
  void setReducedMotion(bool value) => setState(() => _reducedMotion = value);

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _entrance.prepare(_ids, disableAnimations: _reducedMotion);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: _reducedMotion),
      child: Scaffold(
        body: ListView.builder(
          itemCount: _ids.length,
          itemBuilder: (context, index) => AppListEntranceItem(
            key: ValueKey(_ids[index]),
            controller: _entrance,
            itemId: _ids[index],
            child: SizedBox(height: widget.rowHeight, child: Text(_ids[index])),
          ),
        ),
      ),
    );
  }
}
