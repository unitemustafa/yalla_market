import '../../domain/entities/partner_application.dart';

sealed class PartnerApplicationState {
  const PartnerApplicationState();
}

final class PartnerApplicationInitial extends PartnerApplicationState {
  const PartnerApplicationInitial();
}

final class PartnerApplicationSubmitting extends PartnerApplicationState {
  const PartnerApplicationSubmitting();
}

final class PartnerApplicationSuccess extends PartnerApplicationState {
  const PartnerApplicationSuccess(this.receipt);

  final PartnerApplicationReceipt receipt;
}

final class PartnerApplicationFailure extends PartnerApplicationState {
  const PartnerApplicationFailure(this.message);

  final String message;
}
