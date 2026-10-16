import 'dart:isolate';

import '../domain/computation_executor.dart';

class CatalogComputationExecutor implements ComputationExecutor {
  const CatalogComputationExecutor();

  @override
  Future<R> run<Q, R>(
    R Function(Q) computation,
    Q input, {
    required bool background,
  }) => background
      ? _isolated(computation, input)
      : Future<R>.sync(() => computation(input));
}

// This scope captures only the function and input, never a repository, Dio,
// Cubit, or the executor's surrounding object graph.
Future<R> _isolated<Q, R>(R Function(Q) computation, Q input) =>
    Isolate.run(() => computation(input), debugName: 'catalog-computation');
