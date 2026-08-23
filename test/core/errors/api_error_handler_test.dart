import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/api_error_handler.dart';
import 'package:yalla_market/core/errors/failure.dart';

void main() {
  group('ApiErrorHandler', () {
    test('maps connection errors to network failure', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.connectionError,
      );

      final failure = ApiErrorHandler.handle(error);

      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'No internet connection.');
    });

    test('maps unauthorized responses to unauthorized failure', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/profile'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/profile'),
          statusCode: 401,
          data: const {'message': 'Please sign in again.'},
        ),
        type: DioExceptionType.badResponse,
      );

      final failure = ApiErrorHandler.handle(error);

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.statusCode, 401);
      expect(failure.message, 'Please sign in again.');
    });

    test('maps general 429 responses to rate limit failure', () {
      final options = RequestOptions(path: '/orders/create');
      final error = DioException(
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 429,
          data: const {
            'code': 'rate_limited',
            'detail': 'Too many requests. Try again later.',
            'retry_after_seconds': 42,
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final failure = ApiErrorHandler.handle(error);

      expect(failure, isA<RateLimitFailure>());
      expect((failure as RateLimitFailure).retryAfterSeconds, 42);
    });

    test('keeps OTP cooldown distinct and reads Retry-After header', () {
      final options = RequestOptions(path: '/auth/resend-verification');
      final error = DioException(
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 429,
          data: const {'code': 'otp_cooldown'},
          headers: Headers.fromMap({
            'retry-after': ['30'],
          }),
        ),
        type: DioExceptionType.badResponse,
      );

      final failure = ApiErrorHandler.handle(error);

      expect(failure, isA<OtpCooldownFailure>());
      expect((failure as OtpCooldownFailure).retryAfterSeconds, 30);
    });

    test('maps pending login response to email verification failure', () {
      final options = RequestOptions(path: '/auth/login/client');
      final error = DioException(
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 403,
          data: const {
            'code': 'email_verification_required',
            'detail': 'Email verification is required.',
            'email': 'pending@example.com',
            'retry_after_seconds': 30,
            'registration_expires_at': '2026-08-25T10:00:00Z',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final failure = ApiErrorHandler.handle(error);

      expect(failure, isA<EmailVerificationRequiredFailure>());
      final verification = failure as EmailVerificationRequiredFailure;
      expect(verification.email, 'pending@example.com');
      expect(verification.retryAfterSeconds, 30);
      expect(verification.registrationExpiresAt, DateTime.utc(2026, 8, 25, 10));
    });

    test('maps non-Dio errors to unknown failure', () {
      final failure = ApiErrorHandler.handle(Exception('boom'));

      expect(failure, isA<UnknownFailure>());
      expect(failure.message, 'Something went wrong.');
    });
  });
}
