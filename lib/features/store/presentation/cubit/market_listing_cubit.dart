import '../../../../core/presentation/cubit/paged_list_cubit.dart';
import '../../domain/entities/store_data.dart';
import '../../domain/entities/market_listing_page.dart';

class MarketListingCubit
    extends PagedListCubit<StoreMarketData, MarketListingQuery> {
  MarketListingCubit(super.load) : super(idOf: (m) => m.id);
}
