import '../network/api_result.dart';

class DataPage<T> {
  const DataPage({
    required this.items,
    required this.count,
    required this.hasMore,
  });
  final List<T> items;
  final int count;
  final bool hasMore;
}

abstract interface class LoadPageUseCase<T, Q> {
  Future<ApiResult<DataPage<T>>> call(Q query, {int page = 1});
}
