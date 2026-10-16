/// Pure-Dart boundary for CPU work. Jobs must contain sendable data only.
abstract interface class ComputationExecutor {
  Future<R> run<Q, R>(
    R Function(Q) computation,
    Q input, {
    required bool background,
  });
}

const backgroundCatalogThreshold = 1000;

class InlineComputationExecutor implements ComputationExecutor {
  const InlineComputationExecutor();

  @override
  Future<R> run<Q, R>(
    R Function(Q) computation,
    Q input, {
    required bool background,
  }) async => computation(input);
}
