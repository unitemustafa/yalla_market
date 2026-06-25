import '../../domain/entities/home_data.dart';

sealed class HomeState {
  const HomeState();

  HomeData? get data => null;
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading({this.previousData});

  final HomeData? previousData;

  @override
  HomeData? get data => previousData;
}

final class HomeReady extends HomeState {
  const HomeReady(this.home);

  final HomeData home;

  @override
  HomeData get data => home;
}

final class HomeFailure extends HomeState {
  const HomeFailure(this.message, {this.previousData});

  final String message;
  final HomeData? previousData;

  @override
  HomeData? get data => previousData;
}
