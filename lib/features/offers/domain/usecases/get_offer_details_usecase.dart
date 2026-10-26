import '../../../../core/network/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../entities/offer_data.dart';
import '../repositories/offer_repository.dart';

class GetOfferDetailsUseCase {
  const GetOfferDetailsUseCase(this._repository);
  final OfferRepository _repository;
  Future<ApiResult<OfferData>> call(String id) async {
    final parsed = int.tryParse(id);
    if (parsed == null || parsed <= 0) {
      return const ApiResult.failure(ValidationFailure('Invalid offer.'));
    }
    final repository = _repository;
    if (repository is OfferDetailRepository) {
      return (repository as OfferDetailRepository).getOffer(id);
    }
    final result = await repository.getOffers();
    return result.when(
      success: (offers) {
        for (final offer in offers) {
          if (offer.id == id) return ApiResult.success(offer);
        }
        return const ApiResult.failure(
          ServerFailure('Offer is no longer available.'),
        );
      },
      failure: ApiResult.failure,
    );
  }
}
