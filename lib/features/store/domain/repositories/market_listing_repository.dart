import '../../../../core/domain/data_page.dart';
import '../../../../core/network/api_result.dart';
import '../entities/store_data.dart';
import '../entities/market_listing_page.dart';

abstract interface class MarketListingRepository {
  Future<ApiResult<DataPage<StoreMarketData>>> getMarketPage(
    MarketListingQuery query, {
    int page = 1,
  });
}
