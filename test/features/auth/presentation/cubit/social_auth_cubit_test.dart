import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_session.dart';
import 'package:yalla_market/features/auth/domain/entities/social_auth_result.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_state.dart';

import '../../../../helpers/auth_widget_fakes.dart';
import '../../../../helpers/domain_fixtures.dart';

void main() {
  test('unverified social sign-in exposes profile completion state', () async {
    final repository = _SocialAuthRepository(
      socialResult: const SocialAuthResult(
        action: SocialAuthAction.completeProfile,
        provider: SocialAuthProvider.facebook,
        email: 'social@example.com',
        firstName: 'Social',
      ),
    );
    final cubit = AuthCubit(authUseCases(repository));

    await cubit.socialSignIn(provider: SocialAuthProvider.facebook);

    expect(cubit.state, isA<AuthSocialProfileRequired>());
    final state = cubit.state as AuthSocialProfileRequired;
    expect(state.result.email, 'social@example.com');
    await cubit.close();
  });

  test('existing social identity authenticates immediately', () async {
    final repository = _SocialAuthRepository(
      socialResult: SocialAuthResult(
        action: SocialAuthAction.authenticated,
        provider: SocialAuthProvider.google,
        email: sampleUser.email,
        session: sampleSession,
      ),
    );
    final cubit = AuthCubit(authUseCases(repository));

    await cubit.socialSignIn(
      provider: SocialAuthProvider.google,
      rememberMe: true,
    );

    expect(cubit.state, isA<AuthAuthenticated>());
    expect(repository.lastProvider, SocialAuthProvider.google);
    expect(repository.lastRememberMe, isTrue);
    await cubit.close();
  });

  test('completed social signup emits authenticated session', () async {
    final repository = _SocialAuthRepository(
      socialResult: const SocialAuthResult(
        action: SocialAuthAction.completeProfile,
        provider: SocialAuthProvider.google,
        email: 'social@example.com',
      ),
      completedSession: sampleSession,
    );
    final cubit = AuthCubit(authUseCases(repository));
    await cubit.socialSignIn(provider: SocialAuthProvider.google);

    await cubit.completeSocialSignup(
      firstName: 'Social',
      lastName: 'Customer',
      username: 'social.customer',
      phone: '+201001234567',
      city: 'Cairo',
    );

    expect(cubit.state, isA<AuthAuthenticated>());
    await cubit.close();
  });
}

class _SocialAuthRepository extends FakeAuthRepository {
  _SocialAuthRepository({required this.socialResult, this.completedSession});

  final SocialAuthResult socialResult;
  final AuthSession? completedSession;
  SocialAuthProvider? lastProvider;

  @override
  Future<ApiResult<SocialAuthResult>> socialSignIn({
    required SocialAuthProvider provider,
    bool rememberMe = false,
  }) async {
    lastProvider = provider;
    lastRememberMe = rememberMe;
    return ApiResult.success(socialResult);
  }

  @override
  Future<ApiResult<AuthSession>> completeSocialSignup({
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String city,
    bool rememberMe = false,
  }) async {
    return ApiResult.success(completedSession ?? sampleSession);
  }
}
