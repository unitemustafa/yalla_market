import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/app_media/data/remote_app_media_repository.dart';

void main() {
  test('maps public media URLs and ignores unsafe values', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: request,
              data: {
                'onboarding_one_url': 'https://example.com/one.webp',
                'onboarding_two_url': 'javascript:alert(1)',
                'market_login_url': 'https://example.com/intro.mp4',
                'market_login_poster_url': 'https://example.com/poster.webp',
                'market_login_focus': {'x': 0.8, 'y': 0.15},
              },
            ),
          );
        },
      ),
    );

    final result = await RemoteAppMediaRepository(dio).load();

    result.when(
      success: (media) {
        expect(media.onboardingOne, 'https://example.com/one.webp');
        expect(media.onboardingTwo, isNull);
        expect(media.marketLogin, 'https://example.com/intro.mp4');
        expect(media.marketLoginPoster, 'https://example.com/poster.webp');
        expect(media.marketLoginFocus.x, 0.8);
        expect(media.marketLoginFocus.y, 0.15);
      },
      failure: (_) => fail('Expected media response.'),
    );
  });

  test('returns a typed failure when the endpoint fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          handler.reject(DioException(requestOptions: request));
        },
      ),
    );

    final result = await RemoteAppMediaRepository(dio).load();

    result.when(
      success: (_) => fail('Expected a failure.'),
      failure: (failure) => expect(failure.message, isNotEmpty),
    );
  });
}
