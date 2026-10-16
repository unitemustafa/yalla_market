import '../domain/computation_executor.dart';

// Web has no native isolates. Keep the same asynchronous/error contract.
class CatalogComputationExecutor extends InlineComputationExecutor {
  const CatalogComputationExecutor();
}
