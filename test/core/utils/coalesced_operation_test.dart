import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/utils/coalesced_operation.dart';

void main() {
  group('CoalescedOperation', () {
    test(
      'Given an active operation, when another caller runs it, then both wait for the same completion',
      () async {
        final operation = CoalescedOperation();
        final completer = Completer<void>();
        var starts = 0;
        var secondFinished = false;

        final first = operation.run(() {
          starts += 1;
          return completer.future;
        });
        final second = operation.run(() {
          starts += 1;
          return Future<void>.value();
        });
        second.whenComplete(() => secondFinished = true);
        await Future<void>.delayed(Duration.zero);

        expect(starts, 1);
        expect(secondFinished, isFalse);

        completer.complete();
        await Future.wait([first, second]);
        expect(secondFinished, isTrue);
      },
    );

    test(
      'Given reset starts a new session, when the old operation completes, then it cannot clear the new session',
      () async {
        final operation = CoalescedOperation();
        final oldCompleter = Completer<void>();
        final newCompleter = Completer<void>();
        var starts = 0;

        final old = operation.run(() {
          starts += 1;
          return oldCompleter.future;
        });
        operation.reset();
        final current = operation.run(() {
          starts += 1;
          return newCompleter.future;
        });
        oldCompleter.complete();
        await old;

        final joinedCurrent = operation.run(() {
          starts += 1;
          return Future<void>.value();
        });
        expect(starts, 2);

        newCompleter.complete();
        await Future.wait([current, joinedCurrent]);

        await operation.run(() {
          starts += 1;
          return Future<void>.value();
        });
        expect(starts, 3);
      },
    );

    test(
      'Given a failed operation, when it is retried, then the retry starts a new operation',
      () async {
        final operation = CoalescedOperation();
        var starts = 0;

        final failed = operation.run(() {
          starts += 1;
          return Future<void>.error(StateError('offline'));
        });
        await expectLater(failed, throwsStateError);

        await operation.run(() {
          starts += 1;
          return Future<void>.value();
        });
        expect(starts, 2);
      },
    );
  });
}
