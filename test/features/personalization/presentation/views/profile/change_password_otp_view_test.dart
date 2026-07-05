import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/otp/otp_cooldown_store.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
import 'package:yalla_market/features/auth/domain/entities/otp_delivery_result.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_state.dart';
import 'package:yalla_market/features/personalization/presentation/controllers/user_profile_controller.dart';
import 'package:yalla_market/features/personalization/presentation/views/profile/change_password_otp_view.dart';

import '../../../../../helpers/auth_widget_fakes.dart';
import '../../../../../helpers/domain_fixtures.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    UserProfileController.instance.reset();
  });

  testWidgets('first successful code send starts a 30 second resend timer', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpView(tester, repository);

    await tester.tap(find.text('Send code'));
    await tester.pump();

    expect(repository.passwordResetRequests, 1);
    expect(find.text('Resend in 00:30'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Resend in 00:29'), findsOneWidget);

    await tester.pump(const Duration(seconds: 29));
    expect(find.text('Resend code'), findsOneWidget);
  });

  testWidgets('successful resends progress 60 then 120 then 300 seconds', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      passwordResetResults: const [
        OtpDeliveryResult(resendAfterSeconds: 30),
        OtpDeliveryResult(resendAfterSeconds: 60),
        OtpDeliveryResult(resendAfterSeconds: 120),
        OtpDeliveryResult(resendAfterSeconds: 300),
        OtpDeliveryResult(resendAfterSeconds: 300),
      ],
    );
    await _pumpView(tester, repository);

    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));

    await tester.tap(find.text('Resend code'));
    await tester.pump();
    expect(find.text('Resend in 01:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 60));

    await tester.tap(find.text('Resend code'));
    await tester.pump();
    expect(find.text('Resend in 02:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 120));

    await tester.tap(find.text('Resend code'));
    await tester.pump();
    expect(find.text('Resend in 05:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 300));

    await tester.tap(find.text('Resend code'));
    await tester.pump();
    expect(find.text('Resend in 05:00'), findsOneWidget);
  });

  testWidgets('uses resend timer returned by backend response', (tester) async {
    final repository = FakeAuthRepository(
      passwordResetResults: const [OtpDeliveryResult(resendAfterSeconds: 45)],
    );
    await _pumpView(tester, repository);

    await tester.tap(find.text('Send code'));
    await tester.pump();

    expect(find.text('Resend in 00:45'), findsOneWidget);
  });

  testWidgets('failed code send does not start timer or raise resend level', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      passwordResetFailure: const ServerFailure('Could not send.'),
    );
    await _pumpView(tester, repository);

    await tester.tap(find.text('Send code'));
    await tester.pump();

    expect(repository.passwordResetRequests, 1);
    expect(find.text('Send code'), findsOneWidget);
    expect(find.textContaining('Resend in'), findsNothing);
  });

  testWidgets('repeated taps while request is pending send one request', (
    tester,
  ) async {
    final completer = Completer<ApiResult<OtpDeliveryResult>>();
    final repository = FakeAuthRepository(passwordResetCompleters: [completer]);
    await _pumpView(tester, repository);

    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    expect(repository.passwordResetRequests, 1);

    completer.complete(
      const ApiResult.success(OtpDeliveryResult(resendAfterSeconds: 30)),
    );
    await tester.pump();
    expect(find.text('Resend in 00:30'), findsOneWidget);
  });

  testWidgets(
    'successful password reset cancels timer and navigates to login',
    (tester) async {
      final repository = FakeAuthRepository();
      await _pumpView(tester, repository);

      await tester.tap(find.text('Send code'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'NewStrongPassword123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'NewStrongPassword123!',
      );
      await tapChangePasswordButton(tester);

      expect(repository.resetPasswordCalls, 1);
      expect(find.text('Password changed'), findsOneWidget);
      expect(cubitOrInitial(tester), isA<AuthInitial>());
      expect(
        await const OtpCooldownStore().read(
          purpose: OtpPurpose.passwordReset,
          identifier: sampleUser.email,
        ),
        isNull,
      );

      final signInButton = find.byKey(
        const ValueKey('password_changed_sign_in_button'),
      );
      expect(signInButton, findsOneWidget);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('login_route')), findsOneWidget);
      expect(find.byType(ChangePasswordOtpView), findsNothing);
    },
  );

  testWidgets('password reset failure keeps authenticated state', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      resetPasswordFailure: const ValidationFailure('Invalid code.'),
    );
    final cubit = AuthCubit(authUseCases(repository));
    cubit.hydrate(sampleSession);
    await _pumpView(tester, repository, cubit: cubit);

    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'NewStrongPassword123!',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'NewStrongPassword123!',
    );
    await tapChangePasswordButton(tester);

    expect(repository.resetPasswordCalls, 1);
    expect(cubit.state, isA<AuthAuthenticated>());
    expect(find.text('Invalid code.'), findsOneWidget);
    expect(find.text('Resend in 00:30'), findsOneWidget);
    expect(find.text('login'), findsNothing);
    expect(find.text('123456'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('change_password_submit_button')),
      findsOneWidget,
    );
  });
}

Future<void> tapChangePasswordButton(WidgetTester tester) async {
  tester.testTextInput.hide();
  await tester.pump();

  final pageContext = tester.element(find.byType(ChangePasswordOtpView));
  ScaffoldMessenger.of(pageContext).hideCurrentSnackBar();
  await tester.pump(const Duration(milliseconds: 250));

  final submitButton = find.byKey(
    const ValueKey('change_password_submit_button'),
  );

  await tester.scrollUntilVisible(
    submitButton,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();

  expect(submitButton, findsOneWidget);

  await tester.tap(submitButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

AuthState cubitOrInitial(WidgetTester tester) {
  final context = tester.element(find.byType(MaterialApp));
  return context.read<AuthCubit>().state;
}

Future<void> _pumpView(
  WidgetTester tester,
  FakeAuthRepository repository, {
  AuthCubit? cubit,
}) async {
  UserProfileController.instance.updateFromAuthUser(sampleUser);
  final authCubit = cubit ?? AuthCubit(authUseCases(repository));
  addTearDown(authCubit.close);

  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp(
        routes: {
          AppRoutes.login: (_) => const Scaffold(key: ValueKey('login_route')),
        },
        home: const ChangePasswordOtpView(),
      ),
    ),
  );
}
