import '../../domain/entities/store_data.dart';

sealed class StoreState {
  const StoreState();

  StoreData? get data => null;
}

final class StoreInitial extends StoreState {
  const StoreInitial();
}

final class StoreLoading extends StoreState {
  const StoreLoading({this.previousData});

  final StoreData? previousData;

  @override
  StoreData? get data => previousData;
}

final class StoreReady extends StoreState {
  const StoreReady(this.store);

  final StoreData store;

  @override
  StoreData get data => store;
}

final class StoreFailure extends StoreState {
  const StoreFailure(this.message, {this.previousData});

  final String message;
  final StoreData? previousData;

  @override
  StoreData? get data => previousData;
}
