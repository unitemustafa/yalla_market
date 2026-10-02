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
}

class _LocalAppMediaRepository implements AppMediaRepository {
  @override
  Future<ApiResult<AppMedia>> load() async =>
      const ApiResult.success(AppMedia());
}
