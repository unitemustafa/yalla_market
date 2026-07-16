import '../../../../core/constants/app_assets.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/store_data.dart';
import '../../domain/repositories/store_repository.dart';
import '../demo/demo_categories.dart';
import '../demo/demo_shops.dart';

class StoreRepositoryImpl implements StoreRepository {
  @override
  Future<ApiResult<StoreData>> getStore({bool forceRefresh = false}) async {
    try {
      final classifications = _demoClassifications();
      final marketsByClassificationId = <String, List<StoreMarketData>>{};

      for (final classification in classifications) {
        marketsByClassificationId[classification.id] = MarketShops.all
            .where(
              (shop) =>
                  _normalize(shop.categoryName) ==
                  _normalize(classification.name),
            )
            .map(
              (shop) => StoreMarketData(
                id: shop.id,
                name: shop.name,
                branch: shop.cityName,
                status: 'active',
                classificationId: classification.id,
                products: shop.products,
                image: shop.logo,
                accentColorValue: shop.accentColorValue,
              ),
            )
            .toList(growable: false);
      }

      return ApiResult.success(
        StoreData(
          commonClassifications: classifications
              .take(4)
              .toList(growable: false),
          classifications: classifications,
          marketsByClassificationId: marketsByClassificationId,
          latestMarkets: marketsByClassificationId.values
              .expand((markets) => markets)
              .take(15)
              .toList(growable: false),
        ),
      );
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load store data.'),
      );
    }
  }

  List<StoreClassificationData> _demoClassifications() {
    const source = <MarketCategoryData>[
      MarketCategories.restaurants,
      MarketCategories.supermarket,
      MarketCategories.vegetables,
      MarketCategories.fruits,
      MarketCategories.bakeries,
      MarketCategories.pharmacy,
    ];

    return source
        .map(
          (category) => StoreClassificationData(
            id: _slugFrom(category.name),
            name: category.name,
            marketCount: MarketShops.all
                .where(
                  (shop) =>
                      _normalize(shop.categoryName) ==
                      _normalize(category.name),
                )
                .length,
            products: const [],
            image: category.image.isEmpty
                ? AppAssets.temporaryMarketPlaceholder
                : category.image,
            accentColorValue: category.color.toARGB32(),
            classificationType: 'normal',
          ),
        )
        .toList(growable: false);
  }

  String _normalize(String value) => value.trim().toLowerCase();

  String _slugFrom(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
