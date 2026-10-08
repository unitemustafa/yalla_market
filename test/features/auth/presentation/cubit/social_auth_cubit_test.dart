import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_session.dart';
import 'package:yalla_market/features/auth/domain/entities/social_auth_result.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_state.dart';

import '../../../../helpers/auth_widget_fakes.dart';
import '../../../../helpers/domain_fixtures.dart';

void main() {
  test(
    'manual Facebook email is normalized and requires verification',
    () async {
      final repository = _SocialAuthRepository(
        socialResult: const SocialAuthResult(
          action: SocialAuthAction.completeProfile,
          provider: SocialAuthProvider.facebook,
          email: '',
        ),
        completedSession: const AuthSession(
          user: sampleUser,
          otpResendAfterSeconds: 30,
        ),
      );
      final cubit = AuthCubit(authUseCases(repository));
      await cubit.socialSignIn(provider: SocialAuthProvider.facebook);
      await cubit.completeSocialSignup(
        email: ' MUSTAFA@Example.com ',
        deferProfile: true,
      );
      expect(repository.lastSignupEmail, 'mustafa@example.com');
      expect(repository.lastDeferredProfile, isTrue);
      expect(cubit.state, isA<AuthSignupSucceeded>());
      expect((cubit.state as AuthSignupSucceeded).email, sampleUser.email);
      expect(cubit.lastOtpResendAfterSeconds, 30);
      await cubit.close();
    },
  );

  test('manual email matching an account requests password linking', () async {
    final repository = _SocialAuthRepository(
      socialResult: const SocialAuthResult(
        action: SocialAuthAction.completeProfile,
        provider: SocialAuthProvider.facebook,
        email: '',
      ),
      completedFailure: const SocialAccountLinkRequiredFailure(
        email: 'existing@example.com',
      ),
    );
    final cubit = AuthCubit(authUseCases(repository));
    await cubit.socialSignIn(provider: SocialAuthProvider.facebook);
    await cubit.completeSocialSignup(
      email: 'existing@example.com',
      firstName: 'Social',
      lastName: 'Customer',
      username: 'social.customer',
      phone: '+201001234567',
      city: '',
    );
    expect(cubit.state, isA<AuthSocialLinkRequired>());
    final state = cubit.state as AuthSocialLinkRequired;
    expect(state.result.email, 'existing@example.com');
    expect(state.result.provider, SocialAuthProvider.facebook);
    await cubit.linkSocialAccount(
      email: state.result.email,
      password: 'password',
    );
    expect(repository.lastLinkEmail, 'existing@example.com');
    expect(cubit.state, isA<AuthAuthenticated>());
    await cubit.close();
  });
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
  _SocialAuthRepository({
    required this.socialResult,
    this.completedSession,
    this.completedFailure,
  });

  final SocialAuthResult socialResult;
  final AuthSession? completedSession;
  final Failure? completedFailure;
  SocialAuthProvider? lastProvider;
  String? lastSignupEmail;
  bool? lastDeferredProfile;
  String? lastLinkEmail;

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
    String? email,
    String firstName = '',
    String lastName = '',
    String username = '',
    String phone = '',
    String city = '',
    bool rememberMe = false,
    bool deferProfile = false,
  }) async {
    lastSignupEmail = email;
    lastDeferredProfile = deferProfile;
    if (completedFailure case final failure?) return ApiResult.failure(failure);
    return ApiResult.success(completedSession ?? sampleSession);
  }

  @override
  Future<ApiResult<AuthSession>> linkSocialAccount({
    String? email,
    required String password,
    bool rememberMe = false,
  }) async {
    lastLinkEmail = email;
    return ApiResult.success(sampleSession);
  }
}
