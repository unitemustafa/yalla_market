import '../../../../core/domain/data_page.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../entities/store_data.dart';
import '../entities/market_listing_page.dart';
import '../repositories/market_listing_repository.dart';
export '../entities/market_listing_page.dart';
export '../repositories/market_listing_repository.dart';

class GetMarketListingUseCase
    implements LoadPageUseCase<StoreMarketData, MarketListingQuery> {
  const GetMarketListingUseCase(this._repository);
  final MarketListingRepository _repository;
  @override
  Future<ApiResult<DataPage<StoreMarketData>>> call(
    MarketListingQuery query, {
    int page = 1,
  }) {
    if (page < 1) {
      return Future.value(
        const ApiResult.failure(ValidationFailure('Invalid page.')),
      );
    }
    return _repository.getMarketPage(query, page: page);
  }
}
