import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/app_media.dart';
import '../domain/load_app_media.dart';

sealed class AppMediaState {
  const AppMediaState();
}

final class AppMediaLoading extends AppMediaState {
  const AppMediaLoading();
}

final class AppMediaReady extends AppMediaState {
  const AppMediaReady(this.media);
  final AppMedia media;
}

final class AppMediaFailed extends AppMediaState {
  const AppMediaFailed();
}

class AppMediaCubit extends Cubit<AppMediaState> {
  AppMediaCubit(this.loadAppMedia) : super(const AppMediaLoading());
  final LoadAppMedia loadAppMedia;

  Future<void> load() async {
    final result = await loadAppMedia();
    if (isClosed) return;
    emit(
      result.when(
        success: AppMediaReady.new,
        failure: (_) => const AppMediaFailed(),
      ),
    );
  }
}
