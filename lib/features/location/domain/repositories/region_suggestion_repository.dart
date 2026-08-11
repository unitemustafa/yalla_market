import '../../../../core/network/api_result.dart';
import '../entities/dismissed_region_suggestion.dart';

abstract interface class RegionSuggestionRepository {
  Future<ApiResult<DismissedRegionSuggestion?>> getDismissed(String userKey);

  Future<ApiResult<void>> saveDismissed(
    String userKey,
    DismissedRegionSuggestion suggestion,
  );

  Future<ApiResult<void>> clearDismissed(String userKey);
}
