import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/storage/startup_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('returns saved preferences when storage responds', () async {
    SharedPreferences.setMockInitialValues({'app.language_code': 'en'});
    final result = await StartupPreferences.load();

    expect(result, isA<ApiSuccess<SharedPreferences>>());
    expect(
      (result as ApiSuccess<SharedPreferences>).data.getString(
        'app.language_code',
      ),
      'en',
    );
  });

  test('maps a synchronous platform failure to a typed failure', () async {
    final result = await StartupPreferences.load(
      read: () => throw StateError('unavailable'),
    );

    expect((result as ApiFailure).failure, isA<UnknownFailure>());
  });

  test('hung storage times out and late errors do not escape', () {
    fakeAsync((clock) {
      final pending = Completer<SharedPreferences>();
      ApiResult<SharedPreferences>? result;
      unawaited(
        StartupPreferences.load(
          read: () => pending.future,
        ).then((value) => result = value),
      );
      clock.flushMicrotasks();
      expect(result, isNull);

      clock.elapse(const Duration(seconds: 3));
      expect((result as ApiFailure).failure, isA<NetworkFailure>());

      pending.completeError(StateError('late failure'));
      clock.flushMicrotasks();
      expect((result as ApiFailure).failure, isA<NetworkFailure>());
    });
  });
}
