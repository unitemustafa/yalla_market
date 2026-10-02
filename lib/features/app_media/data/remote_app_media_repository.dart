import 'package:dio/dio.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_factory.dart';
import '../../../core/domain/media_focal_point.dart';
import '../domain/app_media.dart';
import '../domain/app_media_repository.dart';

class RemoteAppMediaRepository implements AppMediaRepository {
  RemoteAppMediaRepository(this.dio);
  final Dio dio;

  @override
  Future<ApiResult<AppMedia>> load() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/dashboard/app-media/',
      );
      final data = response.data ?? {};
      String? url(String key) {
        final value = data[key];
        if (value is! String || value.trim().isEmpty) return null;
        final uri = Uri.tryParse(value);
        return uri != null && (uri.scheme == 'https' || uri.scheme == 'http')
            ? value
            : null;
      }

      return ApiResult.success(
        AppMedia(
          onboardingOne: url('onboarding_one_url'),
          onboardingTwo: url('onboarding_two_url'),
          onboardingThree: url('onboarding_three_url'),
          marketLogin: url('market_login_url'),
          marketLoginPoster: url('market_login_poster_url'),
          marketLoginFocus: MediaFocalPoint.fromJson(
            data['market_login_focus'],
            fallback: MediaFocalPoint.topCenter,
          ),
        ),
      );
    } on DioException {
      return const ApiResult.failure(
        NetworkFailure('Could not load app media.'),
      );
    } catch (_) {
      return const ApiResult.failure(
        UnknownFailure('Invalid app media response.'),
      );
    }
  }
}

Dio createAppMediaDio() => Dio(DioFactory.baseOptions());
