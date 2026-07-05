import '../../../../core/network/api_result.dart';
import '../entities/picked_profile_image.dart';
import '../repositories/profile_image_repository.dart';

class PickProfileImageUseCase {
  const PickProfileImageUseCase(this._repository);

  final ProfileImageRepository _repository;

  Future<ApiResult<PickedProfileImage?>> call() =>
      _repository.pickProfileImage();
}
