import 'package:dio/dio.dart';

import '../../../../core/errors/api_error_handler.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/shipping_company.dart';
import '../../domain/repositories/shipping_company_repository.dart';

class ShippingCompanyRemoteRepositoryImpl implements ShippingCompanyRepository {
  ShippingCompanyRemoteRepositoryImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ApiResult<List<ShippingCompanyData>>> getForCity(
    int serviceCityId,
  ) async {
    try {
      final payload = await _apiClient.get<Object?>(
        '/locations/shipping-companies/',
        queryParameters: {'service_city_id': serviceCityId},
      );
      return ApiResult.success(_companiesFromPayload(payload));
    } on DioException catch (error) {
      return ApiResult.failure(ApiErrorHandler.handle(error));
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Could not load shipping companies.'),
      );
    }
  }
}

List<ShippingCompanyData> _companiesFromPayload(Object? payload) {
  final raw = switch (payload) {
    List() => payload,
    Map<String, dynamic>() when payload['results'] is List =>
      payload['results'] as List,
    Map<String, dynamic>() when payload['data'] is List =>
      payload['data'] as List,
    _ => throw const FormatException('Invalid shipping companies response.'),
  };
  final companies = <ShippingCompanyData>[];
  for (final value in raw) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid shipping company response.');
    }
    final company = ShippingCompanyData.fromJson(value);
    if (!company.isValid) {
      throw const FormatException('Invalid shipping company response.');
    }
    companies.add(company);
  }
  return companies;
}
