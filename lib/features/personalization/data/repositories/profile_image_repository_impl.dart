import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/picked_profile_image.dart';
import '../../domain/repositories/profile_image_repository.dart';

class ProfileImageRepositoryImpl implements ProfileImageRepository {
  ProfileImageRepositoryImpl({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<ApiResult<PickedProfileImage?>> pickProfileImage() async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 900,
      );

      if (pickedImage == null) {
        return const ApiResult.success(null);
      }

      return ApiResult.success(
        PickedProfileImage(
          bytes: await pickedImage.readAsBytes(),
          fileName: pickedImage.name,
          mimeType: pickedImage.mimeType,
        ),
      );
    } catch (_) {
      return const ApiResult.failure(UnknownFailure('Could not open gallery.'));
    }
  }
}
