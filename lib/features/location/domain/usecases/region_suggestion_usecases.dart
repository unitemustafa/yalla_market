import '../../../../core/network/api_result.dart';
import '../entities/dismissed_region_suggestion.dart';
import '../repositories/region_suggestion_repository.dart';

class RegionSuggestionUseCases {
  const RegionSuggestionUseCases(this._repository);

  final RegionSuggestionRepository _repository;

  Future<ApiResult<DismissedRegionSuggestion?>> getDismissed(String userKey) {
    return _repository.getDismissed(userKey);
  }

  Future<ApiResult<void>> saveDismissed(
    String userKey,
    DismissedRegionSuggestion suggestion,
  ) {
    return _repository.saveDismissed(userKey, suggestion);
  }

  Future<ApiResult<void>> clearDismissed(String userKey) {
    return _repository.clearDismissed(userKey);
  }
}
