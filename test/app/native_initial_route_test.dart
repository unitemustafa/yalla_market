import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_session.dart';
import 'package:yalla_market/features/auth/domain/repositories/auth_repository.dart';
import 'package:yalla_market/features/splash/presentation/views/splash_view.dart';
import 'package:yalla_market/yalla_market_app.dart';

import '../helpers/auth_widget_fakes.dart';

void main() {
  for (final nativeRoute in [
    'login',
    'order_details',
    'yallamarket://products/42',
  ]) {
    testWidgets('restores the session before native route $nativeRoute', (
      tester,
    ) async {
      tester.platformDispatcher.defaultRouteNameTestValue = nativeRoute;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      SharedPreferences.setMockInitialValues({});
      initServiceLocator();
      final auth = _PendingRestoreRepository();
      await sl.unregister<AuthRepository>();
      sl.registerSingleton<AuthRepository>(auth);
      addTearDown(sl.reset);

      await tester.pumpWidget(const YallaMarketApp());
      await tester.pump();
      expect(find.byType(SplashView), findsOneWidget);
      expect(auth.restoreCalls, 1);
      expect(find.textContaining('No route defined'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}

class _PendingRestoreRepository extends FakeAuthRepository {
  final _restore = Completer<ApiResult<AuthSession?>>();
  int restoreCalls = 0;

  @override
  Future<ApiResult<AuthSession?>> restoreSavedSession() {
    restoreCalls++;
    return _restore.future;
  }
}
