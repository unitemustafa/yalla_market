import 'package:get_it/get_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_client.dart';
import 'package:yalla_market/features/wishlist/data/repositories/wishlist_remote_repository_impl.dart';
import 'package:yalla_market/features/wishlist/data/repositories/wishlist_repository_impl.dart';
import 'package:yalla_market/features/wishlist/di/wishlist_di.dart';
import 'package:yalla_market/features/wishlist/domain/repositories/wishlist_repository.dart';

import '../../../helpers/fake_api_client.dart';

void main() {
  group('registerWishlistDependencies', () {
    test('uses local repository in demo mode', () {
      final sl = GetIt.asNewInstance();

      registerWishlistDependencies(sl, useDemoRepositories: true);

      expect(sl<WishlistRepository>(), isA<WishlistRepositoryImpl>());
    });

    test('uses remote repository in backend mode', () {
      final sl = GetIt.asNewInstance();
      sl.registerLazySingleton<ApiClient>(() => FakeApiClient((_) => const []));

      registerWishlistDependencies(sl, useDemoRepositories: false);

      expect(sl<WishlistRepository>(), isA<WishlistRemoteRepositoryImpl>());
    });
  });
}
