import '../../../../core/network/api_result.dart';
import '../entities/offer_data.dart';

abstract class OfferRepository {
  Future<ApiResult<List<OfferData>>> getOffers();
}
