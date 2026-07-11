import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/routing/auth_guard.dart';
import 'package:yalla_market/core/session/account_inactive_notifier.dart';
import 'package:yalla_market/core/session/session_expired_notifier.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_session.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_user.dart';
import 'package:yalla_market/features/auth/domain/entities/otp_delivery_result.dart';
import 'package:yalla_market/features/auth/domain/repositories/auth_repository.dart';
import 'package:yalla_market/features/auth/domain/usecases/auth_usecases.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_state.dart';

import '../../../../helpers/domain_fixtures.dart';

void main() {
  group('AuthCubit', () {
    setUp(() {
      AuthGuard.clearAuthentication();
    });

    test('restores an existing saved session', () async {
      final repository = _FakeAuthRepository(restoreResult: sampleSession);
      final cubit = AuthCubit(_authUseCases(repository));
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );

      final restored = await cubit.restoreSavedSession();

      expect(restored, isTrue);
      expect(
        (cubit.state as AuthAuthenticated).session.user.email,
        sampleUser.email,
      );
      await expectedStates;
      await cubit.close();
    });

    test('returns to initial when no saved session exists', () async {
      final repository = _FakeAuthRepository();
      final cubit = AuthCubit(_authUseCases(repository));
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthInitial>()]),
      );

      final restored = await cubit.restoreSavedSession();

      expect(restored, isFalse);
      expect(cubit.state, isA<AuthInitial>());
      await expectedStates;
      await cubit.close();
    });

    test('emits authenticated state after login succeeds', () async {
      final repository = _FakeAuthRepository(loginResult: sampleSession);
      final cubit = AuthCubit(_authUseCases(repository));
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
      );

      await cubit.login(
        email: ' mustafa@example.com ',
        password: 'password',
        rememberMe: true,
      );

      expect(repository.lastLoginEmail, 'mustafa@example.com');
      expect(repository.lastRememberMe, isTrue);
      expect((cubit.state as AuthAuthenticated).session, sampleSession);
      await expectedStates;
      await cubit.close();
    });

    test('emits failure state after login fails', () async {
      final repository = _FakeAuthRepository(
        loginFailure: const UnauthorizedFailure('Invalid email or password.'),
      );
      final cubit = AuthCubit(_authUseCases(repository));
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthFailure>()]),
      );

      await cubit.login(email: 'mustafa@example.com', password: 'wrong');

      expect(
        (cubit.state as AuthFailure).message,
        'Invalid email or password.',
      );
      await expectedStates;
      await cubit.close();
    });

    test(
      'emits a login-only disabled state when the account is inactive',
      () async {
        final repository = _FakeAuthRepository(
          loginFailure: const AccountInactiveFailure(),
        );
        final cubit = AuthCubit(_authUseCases(repository));
        final expectedStates = expectLater(
          cubit.stream,
          emitsInOrder([isA<AuthLoading>(), isA<AuthLoginAccountDisabled>()]),
        );

        await cubit.login(email: 'mustafa@example.com', password: 'password');

        expect(cubit.state, isA<AuthLoginAccountDisabled>());
        await expectedStates;
        await cubit.close();
      },
    );

    test(
      'allows a new login attempt after a previously disabled session',
      () async {
        final inactiveNotifier = AccountInactiveNotifier()..notifyInactive();
        final repository = _FakeAuthRepository(
          loginFailure: const UnauthorizedFailure('Invalid email or password.'),
        );
        final cubit = AuthCubit(
          _authUseCases(repository),
          accountInactiveNotifier: inactiveNotifier,
        );
        final expectedStates = expectLater(
          cubit.stream,
          emitsInOrder([isA<AuthLoading>(), isA<AuthFailure>()]),
        );

        await cubit.login(email: 'mustafa@example.com', password: 'wrong');

        expect(inactiveNotifier.isInactive, isFalse);
        expect(cubit.state, isA<AuthFailure>());
        await expectedStates;
        await cubit.close();
      },
    );

    test('emits signup success without authenticating the user', () async {
      final repository = _FakeAuthRepository(loginResult: sampleSession);
      final cubit = AuthCubit(_authUseCases(repository));
      final expectedStates = expectLater(
        cubit.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthSignupSucceeded>()]),
      );

      await cubit.signup(
        firstName: 'Mustafa',
        lastName: 'Ali',
        email: ' mustafa@example.com ',
        password: 'Password123!',
        username: 'mustafa_ali',
        phone: '+201000000000',
      );

      expect((cubit.state as AuthSignupSucceeded).email, sampleUser.email);
      expect(AuthGuard.isAuthenticated, isFalse);
      await expectedStates;
      await cubit.close();
    });

    test(
      'authenticates the pending signup after verification completes',
      () async {
        final repository = _FakeAuthRepository(loginResult: sampleSession);
        final cubit = AuthCubit(_authUseCases(repository));
        final expectedStates = expectLater(
          cubit.stream,
          emitsInOrder([
            isA<AuthLoading>(),
            isA<AuthSignupSucceeded>(),
            isA<AuthAuthenticated>(),
          ]),
        );

        await cubit.signup(
          firstName: 'Mustafa',
          lastName: 'Ali',
          email: 'mustafa@example.com',
          password: 'Password123!',
          username: 'mustafa_ali',
          phone: '+201000000000',
        );
        final completed = await cubit.completeSignupVerification('123456');

        expect(completed, isTrue);
        expect((cubit.state as AuthAuthenticated).session, sampleSession);
        expect(AuthGuard.isAuthenticated, isTrue);
        await expectedStates;
        await cubit.close();
      },
    );

    test(
      'verifies a pending signup without tokens before authenticating',
      () async {
        const pendingSession = AuthSession(user: sampleUser);
        final repository = _FakeAuthRepository(
          loginResult: pendingSession,
          verifyEmailResult: sampleSession,
        );
        final cubit = AuthCubit(_authUseCases(repository));
        final expectedStates = expectLater(
          cubit.stream,
          emitsInOrder([
            isA<AuthLoading>(),
            isA<AuthSignupSucceeded>(),
            isA<AuthLoading>(),
            isA<AuthAuthenticated>(),
          ]),
        );

        await cubit.signup(
          firstName: 'Mustafa',
          lastName: 'Ali',
          email: 'mustafa@example.com',
          password: 'Password123!',
          username: 'mustafa_ali',
          phone: '+201000000000',
        );
        final completed = await cubit.completeSignupVerification('123456');

        expect(completed, isTrue);
        expect(repository.lastVerificationCode, '123456');
        expect((cubit.state as AuthAuthenticated).session, sampleSession);
        await expectedStates;
        await cubit.close();
      },
    );

    test('updates the current authenticated user profile', () async {
      final updatedUser = sampleUser.copyWith(firstName: 'Mona');
      final repository = _FakeAuthRepository(
        loginResult: sampleSession,
        updateProfileResult: updatedUser,
      );
      final cubit = AuthCubit(_authUseCases(repository));
      await cubit.login(email: sampleUser.email, password: 'password');

      final expectedStates = expectLater(
        cubit.stream,
        emits(isA<AuthAuthenticated>()),
      );
      final user = await cubit.updateProfile(firstName: 'Mona');

      expect(user?.firstName, 'Mona');
      expect((cubit.state as AuthAuthenticated).session.user.firstName, 'Mona');
      await expectedStates;
      await cubit.close();
    });

    test('refreshProfile preserves current session tokens', () async {
      final refreshedUser = sampleUser.copyWith(firstName: 'Mona');
      final repository = _FakeAuthRepository(
        loginResult: sampleSession,
        meResult: refreshedUser,
      );
      final cubit = AuthCubit(_authUseCases(repository));
      await cubit.login(email: sampleUser.email, password: 'password');

      final user = await cubit.refreshProfile();
      final session = (cubit.state as AuthAuthenticated).session;

      expect(user, refreshedUser);
      expect(session.user, refreshedUser);
      expect(session.accessToken, sampleSession.accessToken);
      expect(session.refreshToken, sampleSession.refreshToken);
      expect(session.expiresAt, sampleSession.expiresAt);
      await cubit.close();
    });

    test('updateProfile preserves current session tokens', () async {
      final updatedUser = sampleUser.copyWith(firstName: 'Mona');
      final repository = _FakeAuthRepository(
        loginResult: sampleSession,
        updateProfileResult: updatedUser,
      );
      final cubit = AuthCubit(_authUseCases(repository));
      await cubit.login(email: sampleUser.email, password: 'password');

      final user = await cubit.updateProfile(firstName: 'Mona');
      final session = (cubit.state as AuthAuthenticated).session;

      expect(user, updatedUser);
      expect(session.user, updatedUser);
      expect(session.accessToken, sampleSession.accessToken);
      expect(session.refreshToken, sampleSession.refreshToken);
      expect(session.expiresAt, sampleSession.expiresAt);
      await cubit.close();
    });

    test('keeps authenticated state when profile update fails', () async {
      final repository = _FakeAuthRepository(
        loginResult: sampleSession,
        updateProfileFailure: const ValidationFailure('Email is already used.'),
      );
      final cubit = AuthCubit(_authUseCases(repository));
      await cubit.login(email: sampleUser.email, password: 'password');

      final user = await cubit.updateProfile(email: 'taken@example.com');

      expect(user, isNull);
      expect(cubit.state, isA<AuthAuthenticated>());
      expect(cubit.lastProfileUpdateError, 'Email is already used.');
      expect(AuthGuard.isAuthenticated, isTrue);
      await cubit.close();
    });

    test('resetPassword failure keeps authenticated session', () async {
      final repository = _FakeAuthRepository(
        loginResult: sampleSession,
        resetPasswordFailure: const ValidationFailure('Invalid code.'),
      );
      final cubit = AuthCubit(_authUseCases(repository));
      await cubit.login(email: sampleUser.email, password: 'password');

      final success = await cubit.resetPassword(
        email: sampleUser.email,
        code: '000000',
        password: 'NewStrongPassword123!',
        passwordConfirm: 'NewStrongPassword123!',
      );

      expect(success, isFalse);
      expect(cubit.state, isA<AuthAuthenticated>());
      expect(cubit.lastPasswordResetError, 'Invalid code.');
      expect(AuthGuard.isAuthenticated, isTrue);
      await cubit.close();
    });

    test('requestPasswordReset failure keeps authenticated session', () async {
      final repository = _FakeAuthRepository(
        loginResult: sampleSession,
        requestPasswordResetFailure: const ValidationFailure(
          'Please wait before requesting another code.',
        ),
      );
      final cubit = AuthCubit(_authUseCases(repository));
      await cubit.login(email: sampleUser.email, password: 'password');

      final success = await cubit.requestPasswordReset(sampleUser.email);

      expect(success, isFalse);
      expect(cubit.state, isA<AuthAuthenticated>());
      expect(
        cubit.lastPasswordResetError,
        'Please wait before requesting another code.',
      );
      expect(AuthGuard.isAuthenticated, isTrue);
      await cubit.close();
    });

    test(
      'avatar update success refreshes authenticated user avatarUrl',
      () async {
        final updatedUser = sampleUser.copyWith(
          avatarUrl: 'https://example.com/media/avatars/avatar.png',
        );
        final repository = _FakeAuthRepository(
          loginResult: sampleSession,
          updateProfileAvatarResult: updatedUser,
        );
        final cubit = AuthCubit(_authUseCases(repository));
        await cubit.login(email: sampleUser.email, password: 'password');

        final user = await cubit.updateProfileAvatar(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'avatar.png',
        );

        expect(user?.avatarUrl, updatedUser.avatarUrl);
        expect(
          (cubit.state as AuthAuthenticated).session.user.avatarUrl,
          updatedUser.avatarUrl,
        );
        await cubit.close();
      },
    );

    test('avatar update failure keeps authenticated session', () async {
      final repository = _FakeAuthRepository(
        loginResult: sampleSession,
        updateProfileAvatarFailure: const ValidationFailure('Bad photo.'),
      );
      final cubit = AuthCubit(_authUseCases(repository));
      await cubit.login(email: sampleUser.email, password: 'password');

      final user = await cubit.updateProfileAvatar(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'avatar.png',
      );

      expect(user, isNull);
      expect(cubit.state, isA<AuthAuthenticated>());
      expect(cubit.lastProfileUpdateError, 'Bad photo.');
      await cubit.close();
    });

    test('emits session expired when the global session expires', () async {
      final notifier = SessionExpiredNotifier();
      final repository = _FakeAuthRepository(loginResult: sampleSession);
      final cubit = AuthCubit(
        _authUseCases(repository),
        sessionExpiredNotifier: notifier,
      );
      await cubit.login(email: sampleUser.email, password: 'password');
      expect(cubit.state, isA<AuthAuthenticated>());
      expect(AuthGuard.isAuthenticated, isTrue);

      final expectedStates = expectLater(
        cubit.stream,
        emits(isA<AuthSessionExpired>()),
      );
      notifier.notifyExpired();

      expect(cubit.state, isA<AuthSessionExpired>());
      expect(AuthGuard.isAuthenticated, isFalse);
      await expectedStates;
      await cubit.close();
    });
  });
}

AuthUseCases _authUseCases(AuthRepository repository) {
  return AuthUseCases(
    restoreSavedSession: RestoreSavedSessionUseCase(repository),
    login: LoginUseCase(repository),
    checkUsernameAvailability: CheckUsernameAvailabilityUseCase(repository),
    checkEmailRegistration: CheckEmailRegistrationUseCase(repository),
    checkPhoneRegistration: CheckPhoneRegistrationUseCase(repository),
    signup: SignupUseCase(repository),
    verifyEmail: VerifyEmailUseCase(repository),
    resendVerificationCode: ResendVerificationCodeUseCase(repository),
    requestPasswordReset: RequestPasswordResetUseCase(repository),
    resendPasswordResetCode: ResendPasswordResetCodeUseCase(repository),
    resetPassword: ResetPasswordUseCase(repository),
    refreshProfile: RefreshProfileUseCase(repository),
    updateProfile: UpdateProfileUseCase(repository),
    updateProfileAvatar: UpdateProfileAvatarUseCase(repository),
    logout: LogoutUseCase(repository),
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.restoreResult,
    this.loginResult,
    this.loginFailure,
    this.verifyEmailResult,
    this.meResult,
    this.updateProfileResult,
    this.updateProfileFailure,
    this.updateProfileAvatarResult,
    this.updateProfileAvatarFailure,
    this.requestPasswordResetFailure,
    this.resetPasswordFailure,
  });

  final AuthSession? restoreResult;
  final AuthSession? loginResult;
  final Failure? loginFailure;
  final AuthSession? verifyEmailResult;
  final AuthUser? meResult;
  final AuthUser? updateProfileResult;
  final Failure? updateProfileFailure;
  final AuthUser? updateProfileAvatarResult;
  final Failure? updateProfileAvatarFailure;
  final Failure? requestPasswordResetFailure;
  final Failure? resetPasswordFailure;
  String? lastLoginEmail;
  bool? lastRememberMe;
  String? lastVerificationCode;

  @override
  Future<ApiResult<AuthSession?>> restoreSavedSession() async {
    return ApiResult.success(restoreResult);
  }

  @override
  Future<ApiResult<AuthSession>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    lastLoginEmail = email;
    lastRememberMe = rememberMe;

    if (loginFailure case final failure?) {
      return ApiResult.failure(failure);
    }

    return ApiResult.success(loginResult ?? sampleSession);
  }

  @override
  Future<ApiResult<bool>> isUsernameAvailable(String username) async {
    return const ApiResult.success(true);
  }

  @override
  Future<ApiResult<bool>> isEmailRegistered(String email) async {
    return const ApiResult.success(false);
  }

  @override
  Future<ApiResult<bool>> isPhoneRegistered(String phone) async {
    return const ApiResult.success(false);
  }

  @override
  Future<ApiResult<AuthSession>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String username,
    required String phone,
  }) async {
    return ApiResult.success(loginResult ?? sampleSession);
  }

  @override
  Future<ApiResult<AuthSession>> verifyEmail({
    required String email,
    required String code,
  }) async {
    lastVerificationCode = code;
    return ApiResult.success(verifyEmailResult ?? sampleSession);
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> resendVerificationCode(
    String email,
  ) async {
    return const ApiResult.success(OtpDeliveryResult(resendAfterSeconds: 30));
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> requestPasswordReset(
    String email,
  ) async {
    if (requestPasswordResetFailure case final failure?) {
      return ApiResult.failure(failure);
    }
    return const ApiResult.success(OtpDeliveryResult(resendAfterSeconds: 30));
  }

  @override
  Future<ApiResult<OtpDeliveryResult>> resendPasswordResetCode(
    String email,
  ) async {
    return const ApiResult.success(OtpDeliveryResult(resendAfterSeconds: 30));
  }

  @override
  Future<ApiResult<bool>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirm,
  }) async {
    if (resetPasswordFailure case final failure?) {
      return ApiResult.failure(failure);
    }
    return const ApiResult.success(true);
  }

  @override
  Future<ApiResult<AuthUser>> me() async {
    return ApiResult.success(meResult ?? sampleUser);
  }

  @override
  Future<ApiResult<AuthUser>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? gender,
    DateTime? birthDate,
  }) async {
    if (updateProfileFailure case final failure?) {
      return ApiResult.failure(failure);
    }

    return ApiResult.success(updateProfileResult ?? sampleUser);
  }

  @override
  Future<ApiResult<AuthUser>> updateProfileAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (updateProfileAvatarFailure case final failure?) {
      return ApiResult.failure(failure);
    }

    return ApiResult.success(updateProfileAvatarResult ?? sampleUser);
  }

  @override
  Future<ApiResult<bool>> logout() async {
    return const ApiResult.success(true);
  }
}
