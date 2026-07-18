import 'package:dio/dio.dart';

import 'failure.dart';

abstract final class ApiErrorHandler {
  static Failure handle(Object error) {
    if (error is DioException) {
      return _handleDioException(error);
    }

    return const UnknownFailure('Something went wrong.');
  }

  static Failure _handleDioException(DioException error) {
    if (_isAccountInactive(error.response?.data)) {
      return const AccountInactiveFailure();
    }
    final statusCode = error.response?.statusCode;
    final message =
        _messageFromResponse(error.response) ?? _fallbackMessage(error);

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate => NetworkFailure(
        message,
        statusCode: statusCode,
      ),
      DioExceptionType.cancel => const NetworkFailure('Request was cancelled.'),
      DioExceptionType.badResponse => _failureFromStatusCode(
        statusCode,
        message,
        error.response,
      ),
      DioExceptionType.unknown => UnknownFailure(
        message,
        statusCode: statusCode,
      ),
    };
  }

  static bool _isAccountInactive(Object? data) {
    return data is Map && data['code']?.toString() == 'account_inactive';
  }

  static Failure _failureFromStatusCode(
    int? statusCode,
    String message,
    Response<dynamic>? response,
  ) {
    if (statusCode == null) {
      return ServerFailure(message);
    }

    if (statusCode == 429) {
      final retryAfterSeconds = _retryAfterSeconds(response);
      if (_stringFromResponse(response, 'code') == 'otp_cooldown') {
        return OtpCooldownFailure(
          message,
          retryAfterSeconds: retryAfterSeconds,
        );
      }
      return RateLimitFailure(message, retryAfterSeconds: retryAfterSeconds);
    }

    return switch (statusCode) {
      400 || 422 => ValidationFailure(message, statusCode: statusCode),
      401 || 403 => UnauthorizedFailure(message, statusCode: statusCode),
      >= 500 => ServerFailure(message, statusCode: statusCode),
      _ => ServerFailure(message, statusCode: statusCode),
    };
  }

  static String? _messageFromResponse(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }

      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }

      final nonFieldErrors = _firstString(data['non_field_errors']);
      if (nonFieldErrors != null) return nonFieldErrors;

      for (final entry in data.entries) {
        final value = entry.value;
        final fieldMessage = _firstString(value);
        if (fieldMessage != null) return fieldMessage;
      }
    }

    return null;
  }

  static int? _intFromResponse(Response<dynamic>? response, String key) {
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final value = data[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
    }
    return null;
  }

  static String? _stringFromResponse(Response<dynamic>? response, String key) {
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final value = data[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }
    return null;
  }

  static int _retryAfterSeconds(Response<dynamic>? response) {
    final bodyValue = _intFromResponse(response, 'retry_after_seconds');
    if (bodyValue != null && bodyValue > 0) return bodyValue;
    final headerValue = response?.headers.value('retry-after');
    return int.tryParse(headerValue ?? '') ?? 0;
  }

  static String? _firstString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is List) {
      for (final item in value) {
        final message = _firstString(item);
        if (message != null) return message;
      }
    }
    if (value is Map) {
      for (final item in value.values) {
        final message = _firstString(item);
        if (message != null) return message;
      }
    }
    return null;
  }

  static String _fallbackMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'Connection timed out.',
      DioExceptionType.connectionError => 'No internet connection.',
      DioExceptionType.badCertificate => 'Unable to verify the server.',
      DioExceptionType.badResponse => 'Server error.',
      DioExceptionType.cancel => 'Request was cancelled.',
      DioExceptionType.unknown => 'Something went wrong.',
    };
  }
}
