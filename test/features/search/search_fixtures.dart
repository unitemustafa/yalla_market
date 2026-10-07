import 'dart:async';

import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/location/domain/entities/city_data.dart';
import 'package:yalla_market/features/location/domain/repositories/location_repository.dart';
import 'package:yalla_market/features/search/domain/entities/catalog_search_results.dart';
import 'package:yalla_market/features/search/domain/repositories/catalog_search_repository.dart';
import 'package:yalla_market/features/store/domain/entities/category_data.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';

const searchCategory = CategoryData(
  id: '3',
  name: 'مطاعم',
  slug: 'restaurants',
  productCount: 1,
  marketCount: 1,
  image: '',
  galleryImages: [],
  accentColorValue: 0xFF013C7E,
);
const searchMarket = StoreMarketData(
  id: '7',
  name: 'مطعم النور',
  branch: '',
  status: 'active',
  classificationId: '3',
  products: [],
  image: '',
  accentColorValue: 0xFF013C7E,
);
const searchProduct = ProductData(
  id: '42',
  title: 'بيتزا',
  brand: 'مطعم النور',
  price: '100',
  oldPrice: null,
  discount: '',
  image: '',
  tags: [],
);
const searchResults = CatalogSearchResults(
  products: [searchProduct],
  markets: [searchMarket],
  categories: [searchCategory],
);

class SearchLocationRepository implements LocationRepository {
  ApiResult<CityData?> result = const ApiResult.success(
    CityData(name: 'Cairo', slug: 'cairo'),
  );

  @override
  Future<ApiResult<CityData?>> getSelectedCity() async => result;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestCatalogSearchRepository implements CatalogSearchRepository {
  final calls = <({String query, String city, int page})>[];
  FutureOr<ApiResult<CatalogSearchResults>> Function(String query, int page)?
  handler;

  @override
  Future<ApiResult<CatalogSearchResults>> search(
    String query, {
    required String citySlug,
    int page = 1,
  }) async {
    calls.add((query: query, city: citySlug, page: page));
    return await (handler?.call(query, page) ??
        const ApiResult.success(searchResults));
  }
}
