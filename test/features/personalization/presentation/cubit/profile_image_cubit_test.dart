import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/personalization/domain/entities/picked_profile_image.dart';
import 'package:yalla_market/features/personalization/domain/repositories/profile_image_repository.dart';
import 'package:yalla_market/features/personalization/domain/usecases/pick_profile_image_usecase.dart';
import 'package:yalla_market/features/personalization/presentation/cubit/profile_image_cubit.dart';

void main() {
  group('ProfileImageCubit', () {
    test('emits success when profile image is picked', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final image = PickedProfileImage(
        bytes: bytes,
        fileName: 'avatar.png',
        mimeType: 'image/png',
      );
      final cubit = ProfileImageCubit(
        PickProfileImageUseCase(_FakeProfileImageRepository(image)),
      );
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<ProfileImageLoading>(), isA<ProfileImageSuccess>()]),
      );

      final result = await cubit.pickProfileImage();

      expect(result?.bytes, bytes);
      expect(result?.fileName, 'avatar.png');
      await expectedStates;

      await cubit.close();
    });

    test('emits failure when image picking fails', () async {
      final cubit = ProfileImageCubit(
        PickProfileImageUseCase(_FakeProfileImageRepository.failure()),
      );
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<ProfileImageLoading>(), isA<ProfileImageFailure>()]),
      );

      final result = await cubit.pickProfileImage();

      expect(result, isNull);
      await expectedStates;

      await cubit.close();
    });
  });
}

class _FakeProfileImageRepository implements ProfileImageRepository {
  _FakeProfileImageRepository(this.image) : shouldFail = false;

  _FakeProfileImageRepository.failure() : image = null, shouldFail = true;

  final PickedProfileImage? image;
  final bool shouldFail;

  @override
  Future<ApiResult<PickedProfileImage?>> pickProfileImage() async {
    if (shouldFail) {
      return const ApiResult.failure(UnknownFailure('Could not open gallery.'));
    }

    return ApiResult.success(image);
  }
}
