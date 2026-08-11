import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/personalization/domain/entities/partner_application.dart';
import 'package:yalla_market/features/personalization/domain/repositories/partner_application_repository.dart';
import 'package:yalla_market/features/personalization/domain/usecases/submit_partner_application_usecase.dart';
import 'package:yalla_market/features/personalization/presentation/cubit/partner_application_cubit.dart';
import 'package:yalla_market/features/personalization/presentation/cubit/partner_application_state.dart';

void main() {
  const request = PartnerApplicationRequest(
    businessName: 'Yalla Shop',
    contactFirstName: 'Yalla',
    contactLastName: 'Owner',
    businessType: 'shop',
    branchesCount: 1,
    applicantRole: 'owner_partner',
    hasTradeLicense: true,
    email: 'owner@example.com',
    mobileNumber: '01000000000',
    landline: '',
    whatsappOptIn: true,
    notes: '',
  );

  test('emits submitting then success and forwards the request', () async {
    final repository = _FakePartnerApplicationRepository(
      const ApiResult.success(
        PartnerApplicationReceipt(
          id: '42',
          businessName: 'Yalla Shop',
          status: 'pending',
          createdAt: null,
        ),
      ),
    );
    final cubit = PartnerApplicationCubit(
      SubmitPartnerApplicationUseCase(repository),
    );
    final states = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<PartnerApplicationSubmitting>(),
        isA<PartnerApplicationSuccess>(),
      ]),
    );

    final result = await cubit.submit(request);

    expect(repository.request, same(request));
    expect(result, isA<PartnerApplicationSuccess>());
    await states;
    await cubit.close();
  });

  test('emits a testable failure message', () async {
    final repository = _FakePartnerApplicationRepository(
      const ApiResult.failure(ValidationFailure('Invalid application.')),
    );
    final cubit = PartnerApplicationCubit(
      SubmitPartnerApplicationUseCase(repository),
    );

    final result = await cubit.submit(request);

    expect(result, isA<PartnerApplicationFailure>());
    expect(
      (result as PartnerApplicationFailure).message,
      'Invalid application.',
    );
    await cubit.close();
  });
}

class _FakePartnerApplicationRepository
    implements PartnerApplicationRepository {
  _FakePartnerApplicationRepository(this.result);

  final ApiResult<PartnerApplicationReceipt> result;
  PartnerApplicationRequest? request;

  @override
  Future<ApiResult<PartnerApplicationReceipt>> submit(
    PartnerApplicationRequest request,
  ) async {
    this.request = request;
    return result;
  }
}
