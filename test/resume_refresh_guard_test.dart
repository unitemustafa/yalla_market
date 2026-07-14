import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/yalla_market_app.dart';

void main() {
  test('valid resumed session refreshes home once', () async {
    final guard = ResumeRefreshGuard();
    var validations = 0;
    var homeRefreshes = 0;
    var orderRefreshes = 0;

    await guard.run(
      validateSession: () async {
        validations += 1;
        return true;
      },
      refreshHome: () async => homeRefreshes += 1,
      refreshOrders: () async => orderRefreshes += 1,
    );

    expect(validations, 1);
    expect(homeRefreshes, 1);
    expect(orderRefreshes, 1);
  });

  test('invalid or signed-out resumed session does not refresh home', () async {
    final guard = ResumeRefreshGuard();
    var refreshes = 0;

    await guard.run(
      validateSession: () async => false,
      refreshHome: () async => refreshes += 1,
    );

    expect(refreshes, 0);
  });

  test('repeated resumed events do not start concurrent refreshes', () async {
    final guard = ResumeRefreshGuard();
    final validation = Completer<bool>();
    var validations = 0;
    var refreshes = 0;

    final first = guard.run(
      validateSession: () {
        validations += 1;
        return validation.future;
      },
      refreshHome: () async => refreshes += 1,
    );
    final second = guard.run(
      validateSession: () async {
        validations += 1;
        return true;
      },
      refreshHome: () async => refreshes += 1,
    );
    validation.complete(true);
    await Future.wait([first, second]);

    expect(validations, 1);
    expect(refreshes, 1);
  });
}
