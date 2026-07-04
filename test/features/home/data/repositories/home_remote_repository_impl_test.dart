import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/address_required_error.dart';
import 'package:yalla_market/core/errors/region_required_error.dart';
import 'package:yalla_market/features/home/data/repositories/home_remote_repository_impl.dart';

import '../../../../helpers/fake_api_client.dart';

void main() {
  test('maps a missing address response to the add address message', () async {
    final repository = HomeRemoteRepositoryImpl(
      FakeApiClient((_) => throw _addressRequiredException()),
    );

    final result = await repository.getHome();

    result.when(
      success: (_) => fail('Expected the request to fail.'),
      failure: (failure) => expect(failure.message, addressRequiredMessage),
    );
  });

  test(
    'maps requires_region_selection to the region required message',
    () async {
      final repository = HomeRemoteRepositoryImpl(
        FakeApiClient((_) => throw _regionRequiredException()),
      );

      final result = await repository.getHome();

      result.when(
        success: (_) => fail('Expected the request to fail.'),
        failure: (failure) => expect(failure.message, regionRequiredMessage),
      );
    },
  );
}

DioException _addressRequiredException() {
  final options = RequestOptions(path: '/home/');
  return DioException(
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: 400,
      data: {
        'detail': 'A user address is required before loading the home page.',
      },
    ),
    type: DioExceptionType.badResponse,
  );
}

DioException _regionRequiredException() {
  final options = RequestOptions(path: '/home/');
  return DioException(
    requestOptions: options,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: 400,
      data: {'requires_region_selection': true, 'current_selection': null},
    ),
    type: DioExceptionType.badResponse,
  );
}
