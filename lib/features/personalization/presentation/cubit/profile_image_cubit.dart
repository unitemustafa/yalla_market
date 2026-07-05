import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/picked_profile_image.dart';
import '../../domain/usecases/pick_profile_image_usecase.dart';

sealed class ProfileImageState {
  const ProfileImageState();
}

final class ProfileImageInitial extends ProfileImageState {
  const ProfileImageInitial();
}

final class ProfileImageLoading extends ProfileImageState {
  const ProfileImageLoading();
}

final class ProfileImageSuccess extends ProfileImageState {
  const ProfileImageSuccess(this.image);

  final PickedProfileImage image;
}

final class ProfileImageFailure extends ProfileImageState {
  const ProfileImageFailure(this.message);

  final String message;
}

class ProfileImageCubit extends Cubit<ProfileImageState> {
  ProfileImageCubit(this._pickProfileImageUseCase)
    : super(const ProfileImageInitial());

  final PickProfileImageUseCase _pickProfileImageUseCase;

  Future<PickedProfileImage?> pickProfileImage() async {
    emit(const ProfileImageLoading());

    final result = await _pickProfileImageUseCase();
    return result.when(
      success: (image) {
        if (image == null) {
          emit(const ProfileImageInitial());
          return null;
        }

        emit(ProfileImageSuccess(image));
        return image;
      },
      failure: (failure) {
        emit(ProfileImageFailure(failure.message));
        return null;
      },
    );
  }
}
