import '../errors/failure.dart';

enum DataOrigin { network, cache }

sealed class ApiResult<T> {
  const ApiResult();

  const factory ApiResult.success(
    T data, {
    DataOrigin origin,
    DateTime? savedAt,
  }) = ApiSuccess<T>;

  const factory ApiResult.failure(Failure failure) = ApiFailure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      ApiSuccess<T>(:final data) => success(data),
      ApiFailure<T>(failure: final error) => failure(error),
    };
  }
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data, {this.origin = DataOrigin.network, this.savedAt});

  final T data;
  final DataOrigin origin;
  final DateTime? savedAt;
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.failure);

  final Failure failure;
}
