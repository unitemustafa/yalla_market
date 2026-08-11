import '../../../../core/network/api_result.dart';
import '../entities/offer_data.dart';
import '../repositories/offer_repository.dart';

class GetOffersUseCase {
  const GetOffersUseCase(this._repository);

  final OfferRepository _repository;

  Future<ApiResult<List<OfferData>>> call() => _repository.getOffers();
}
