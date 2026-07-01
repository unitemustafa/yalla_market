import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:yalla_market/core/network/api_client.dart';
import 'package:yalla_market/features/store/di/store_di.dart';
import 'package:yalla_market/features/store/domain/usecases/get_my_orders_usecase.dart';

import '../../../helpers/fake_api_client.dart';

void main() {
  group('registerStoreDependencies', () {
    late GetIt sl;

    setUp(() {
      sl = GetIt.asNewInstance();
    });

    test(
      'uses OrderRemoteRepositoryImpl for order history in backend mode',
      () async {
        final apiClient = FakeApiClient((request) {
          expect(request.method, 'GET');
          expect(request.path, '/orders/my/');
          return const [];
        });
        sl.registerLazySingleton<ApiClient>(() => apiClient);

        registerStoreDependencies(sl, useDemoRepositories: false);

        final result = await sl<GetMyOrdersUseCase>()();

        result.when(
          success: (orders) => expect(orders, isEmpty),
          failure: (failure) => fail(failure.message),
        );
        expect(apiClient.requests, hasLength(1));
      },
    );

    test(
      'keeps demo mode on the existing unavailable order repository',
      () async {
        registerStoreDependencies(sl, useDemoRepositories: true);

        final result = await sl<GetMyOrdersUseCase>()();

        result.when(
          success: (_) => fail('Demo mode should keep the existing behavior.'),
          failure: (failure) {
            expect(failure.message, isNotEmpty);
          },
        );
      },
    );
  });
}
