import '../../../../core/domain/data_page.dart';
import 'store_data.dart';

typedef MarketListingQuery = ({
  String classificationId,
  String query,
  String? typeId,
  bool popular,
  bool latest,
  String scope,
});

class MarketListingPage extends DataPage<StoreMarketData> {
  const MarketListingPage({
    required super.items,
    required super.count,
    required super.hasMore,
    this.types = const [],
    this.selectedTypeId,
    this.totalCount = 0,
  });
  final List<StoreMarketTypeData> types;
  final String? selectedTypeId;
  final int totalCount;
}
