import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/region_hint_usecases.dart';

class RegionHintCubit extends Cubit<bool> {
  RegionHintCubit(this._useCases) : super(false);

  final RegionHintUseCases _useCases;
  String? _userId;

  Future<void> load({
    required String userId,
    required DateTime? dateJoined,
  }) async {
    _userId = userId;
    emit(false);
    final result = await _useCases.shouldShow(
      userId: userId,
      dateJoined: dateJoined,
      now: DateTime.now(),
    );
    if (isClosed || _userId != userId) return;
    emit(result.when(success: (show) => show, failure: (_) => false));
  }

  Future<void> dismiss() async {
    final userId = _userId;
    if (userId == null || !state) return;
    emit(false);
    await _useCases.markSeen(userId);
  }
}
