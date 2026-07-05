sealed class Failure {
  const Failure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.statusCode});
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.statusCode});
}

final class OtpCooldownFailure extends Failure {
  const OtpCooldownFailure(
    super.message, {
    required this.retryAfterSeconds,
    super.statusCode = 429,
  });

  final int retryAfterSeconds;
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message, {super.statusCode});
}

final class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.statusCode});
}
