import '../../../../core/network/api_result.dart';
import '../../domain/entities/offer_data.dart';
import '../../domain/repositories/offer_repository.dart';

class OfferRepositoryImpl implements OfferRepository {
  const OfferRepositoryImpl();

  @override
  Future<ApiResult<List<OfferData>>> getOffers() async {
    return const ApiResult.success(<OfferData>[]);
  }
}
