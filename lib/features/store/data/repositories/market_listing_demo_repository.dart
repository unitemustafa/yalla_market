import '../../../../core/domain/data_page.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/store_data.dart';
import '../../domain/repositories/store_repository.dart';
import '../../domain/usecases/get_market_listing_usecase.dart';

/// Compatibility for local/demo catalogs; production implements server paging.
class MarketListingDemoRepository implements MarketListingRepository {
  const MarketListingDemoRepository(this._store);
  final StoreRepository _store;
  @override
  Future<ApiResult<DataPage<StoreMarketData>>> getMarketPage(
    MarketListingQuery query, {
    int page = 1,
  }) async {
    final result = await _store.getStore();
    if (result case ApiFailure(:final failure)) {
      return ApiResult.failure(failure);
    }
    final store = (result as ApiSuccess<StoreData>).data;
    List<StoreMarketData> markets;
    if (query.classificationId.isNotEmpty) {
      final detail = await _store.getClassificationMarkets(
        query.classificationId,
      );
      if (detail case ApiFailure(:final failure)) {
        return ApiResult.failure(failure);
      }
      markets = (detail as ApiSuccess<List<StoreMarketData>>).data;
    } else {
      markets = query.popular ? store.popularMarkets : store.latestMarkets;
    }
    final ids = {for (final market in markets) ...market.marketTypeIds};
    final types = store.classifications
        .where((c) => c.id == query.classificationId)
        .expand((c) => c.marketTypes)
        .where((t) => ids.contains(t.id))
        .toList(growable: false);
    final type = query.typeId ?? types.firstOrNull?.id;
    final normalized = query.query.trim().toLowerCase();
    final filtered = markets
        .where(
          (m) =>
              (type == null || m.marketTypeIds.contains(type)) &&
              (m.name.toLowerCase().contains(normalized) ||
                  m.branch.toLowerCase().contains(normalized)),
        )
        .toList(growable: false);
    return ApiResult.success(
      MarketListingPage(
        items: List.unmodifiable(filtered.skip((page - 1) * 30).take(30)),
        count: filtered.length,
        hasMore: page * 30 < filtered.length,
        types: types,
        selectedTypeId: type,
        totalCount: markets.length,
      ),
    );
  }
}
