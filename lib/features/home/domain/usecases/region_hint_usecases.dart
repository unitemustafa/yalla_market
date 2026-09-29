import '../../../../core/network/api_result.dart';
import '../repositories/region_hint_repository.dart';

class RegionHintUseCases {
  const RegionHintUseCases(this._repository);

  final RegionHintRepository _repository;

  Future<ApiResult<bool>> shouldShow({
    required String userId,
    required DateTime? dateJoined,
    required DateTime now,
  }) async {
    if (userId.trim().isEmpty || dateJoined == null) {
      return const ApiResult.success(false);
    }
    final age = now.toUtc().difference(dateJoined.toUtc());
    if (age.isNegative || age > const Duration(days: 7)) {
      return const ApiResult.success(false);
    }
    final result = await _repository.hasSeen(userId);
    return result.when(
      success: (seen) => ApiResult.success(!seen),
      failure: (failure) => ApiResult.failure(failure),
    );
  }

  Future<ApiResult<void>> markSeen(String userId) =>
      _repository.markSeen(userId);
}
