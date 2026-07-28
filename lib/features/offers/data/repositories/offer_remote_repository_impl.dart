import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/offer_data.dart';
import '../../domain/repositories/offer_repository.dart';

class OfferRemoteRepositoryImpl implements OfferRepository {
  const OfferRemoteRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<List<OfferData>>> getOffers() async {
    try {
      final payload = await _apiClient.get<Object?>('/offers/');
      if (payload is! List) {
        return const ApiResult.success(<OfferData>[]);
      }
      return ApiResult.success(
        payload
            .whereType<Map<String, dynamic>>()
            .map(OfferData.fromJson)
            .toList(growable: false),
      );
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(UnknownFailure('Could not load offers.'));
    }
  }
}
