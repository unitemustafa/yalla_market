import '../../../../core/network/api_result.dart';

abstract interface class RegionHintRepository {
  Future<ApiResult<bool>> hasSeen(String userId);

  Future<ApiResult<void>> markSeen(String userId);
}
