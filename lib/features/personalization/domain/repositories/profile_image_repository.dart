import '../../../../core/network/api_result.dart';
import '../entities/picked_profile_image.dart';

abstract class ProfileImageRepository {
  Future<ApiResult<PickedProfileImage?>> pickProfileImage();
}
