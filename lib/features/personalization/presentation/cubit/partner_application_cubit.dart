import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/partner_application.dart';
import '../../domain/usecases/submit_partner_application_usecase.dart';
import 'partner_application_state.dart';

class PartnerApplicationCubit extends Cubit<PartnerApplicationState> {
  PartnerApplicationCubit(this._submitApplication)
    : super(const PartnerApplicationInitial());

  final SubmitPartnerApplicationUseCase _submitApplication;

  Future<PartnerApplicationState> submit(
    PartnerApplicationRequest request,
  ) async {
    if (state is PartnerApplicationSubmitting) return state;

    emit(const PartnerApplicationSubmitting());
    final result = await _submitApplication(request);
    final nextState = result.when<PartnerApplicationState>(
      success: PartnerApplicationSuccess.new,
      failure: (failure) => PartnerApplicationFailure(failure.message),
    );
    emit(nextState);
    return nextState;
  }
}
