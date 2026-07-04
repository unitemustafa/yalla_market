import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/views/verify_email_view.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';

import '../../../../helpers/auth_widget_fakes.dart';

void main() {
  setUp(() {
    AppLanguageController.instance.value = AppLanguage.english;
  });

  testWidgets('shows six LTR OTP boxes and distributes pasted digits', (
    tester,
  ) async {
    await _pumpVerifyEmail(tester);

    for (var index = 0; index < 6; index++) {
      expect(find.byKey(ValueKey('otp_digit_$index')), findsOneWidget);
    }

    final directionality = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('otp_digit_0')),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(directionality.textDirection, TextDirection.ltr);

    await tester.enterText(
      find.byKey(const ValueKey('otp_code_field')),
      '123456',
    );
    await tester.pump();

    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      expect(find.text(digit), findsOneWidget);
    }
  });

  testWidgets('does not overflow at narrow and wider widths', (tester) async {
    for (final width in [320.0, 430.0]) {
      await tester.binding.setSurfaceSize(Size(width, 850));
      await _pumpVerifyEmail(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('confirm button is disabled before six digits', (tester) async {
    await _pumpVerifyEmail(tester);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('resend shows loading and disables repeated taps', (
    tester,
  ) async {
    final completer = Completer<ApiResult<bool>>();
    final repository = FakeAuthRepository(resendCompleter: completer);
    await _pumpVerifyEmail(tester, repository: repository);

    await _tapResend(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Sending...'), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );

    await tester.tap(find.byType(TextButton), warnIfMissed: false);
    await tester.pump();
    expect(repository.resendCalls, 1);

    completer.complete(const ApiResult.success(true));
    await tester.pump();
  });

  testWidgets('failed resend hides loading and does not start cooldown', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      resendFailure: const NetworkFailure('Network down'),
    );
    await _pumpVerifyEmail(tester, repository: repository);

    await _tapResend(tester);
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Resend Email'), findsOneWidget);
    expect(find.textContaining('Resend in'), findsNothing);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('successful resend starts cooldown once', (tester) async {
    final repository = FakeAuthRepository();
    await _pumpVerifyEmail(tester, repository: repository);

    await _tapResend(tester);
    await tester.pump();
    await tester.pump();

    expect(repository.resendCalls, 1);
    expect(find.text('Resend in 30s'), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );

    await tester.tap(find.byType(TextButton), warnIfMissed: false);
    await tester.pump();
    expect(repository.resendCalls, 1);
  });
}

Future<void> _pumpVerifyEmail(
  WidgetTester tester, {
  FakeAuthRepository? repository,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 850));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final authRepository = repository ?? FakeAuthRepository();
  final authCubit = AuthCubit(authUseCases(authRepository));
  await authCubit.signup(
    firstName: 'Mustafa',
    lastName: 'Ali',
    email: 'manual@example.com',
    password: 'Password1!',
    username: 'manual2026',
    phone: '+201000000000',
  );
  final locationCubit = LocationCubit(
    locationUseCases(FakeLocationRepository()),
  );
  addTearDown(authCubit.close);
  addTearDown(locationCubit.close);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
        BlocProvider.value(value: locationCubit),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppTranslations.supportedLocales,
        locale: Locale('en'),
        home: VerifyEmailView(email: 'manual@example.com'),
      ),
    ),
  );
}

Future<void> _tapResend(WidgetTester tester) async {
  final finder = find.text('Resend Email');
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}
