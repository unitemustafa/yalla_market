import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/app/di/service_locator.dart';
import 'package:yalla_market/yalla_market_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/app_media/domain/app_media.dart';
import 'package:yalla_market/features/app_media/domain/app_media_repository.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    initServiceLocator();
    await sl.unregister<AppMediaRepository>();
    sl.registerLazySingleton<AppMediaRepository>(_LocalAppMediaRepository.new);
  });

  tearDownAll(() => sl.reset());

  testWidgets('renders the app shell', (tester) async {
    await tester.pumpWidget(const YallaMarketApp());
    await tester.pump();

    expect(find.byKey(const ValueKey('splash_brand_logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('splash_tagline')), findsNothing);
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
    'centers the iPad app shell and expands it again in portrait',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1024, 768);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const YallaMarketApp());
      await tester.pump();

      expect(
        tester.getRect(find.byType(Navigator)),
        const Rect.fromLTWH(224, 0, 576, 768),
      );
      final splashContext = tester.element(
        find.byKey(const ValueKey('splash_brand_logo')),
      );
      expect(MediaQuery.sizeOf(splashContext), const Size(576, 768));
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(768, 1024);
      await tester.pump();
      expect(tester.getSize(find.byType(Navigator)), const Size(768, 1024));
      expect(MediaQuery.sizeOf(splashContext), const Size(768, 1024));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}

class _LocalAppMediaRepository implements AppMediaRepository {
  @override
  Future<ApiResult<AppMedia>> load() async =>
      const ApiResult.success(AppMedia());
}
