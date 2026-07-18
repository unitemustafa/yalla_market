import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/auth/domain/entities/otp_delivery_result.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/views/verify_email_view.dart';
import 'package:yalla_market/features/auth/presentation/widgets/auth_top_bar.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';

import '../../../../helpers/auth_widget_fakes.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
    for (final size in const [
      Size(320, 480),
      Size(360, 600),
      Size(430, 850),
      Size(600, 900),
    ]) {
      await _pumpVerifyEmail(
        tester,
        surfaceSize: size,
        textScale: size.height == 480 ? 1.5 : 1,
      );
      final fixedScroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('fixed_auth_page_scroll')),
      );
      expect(
        fixedScroll.physics,
        size.height < 700
            ? isA<ClampingScrollPhysics>()
            : isA<NeverScrollableScrollPhysics>(),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('does not overflow around iPhone safe areas', (tester) async {
    const cases = <({Size size, FakeViewPadding padding, bool scrolls})>[
      (size: Size(320, 568), padding: FakeViewPadding(top: 20), scrolls: true),
      (
        size: Size(390, 844),
        padding: FakeViewPadding(top: 47, bottom: 34),
        scrolls: false,
      ),
      (
        size: Size(430, 932),
        padding: FakeViewPadding(top: 59, bottom: 34),
        scrolls: false,
      ),
      (
        size: Size(844, 390),
        padding: FakeViewPadding(left: 47, right: 47, bottom: 21),
        scrolls: true,
      ),
    ];

    for (final testCase in cases) {
      await _pumpVerifyEmail(
        tester,
        surfaceSize: testCase.size,
        viewPadding: testCase.padding,
      );
      final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('fixed_auth_page_scroll')),
      );
      expect(
        scroll.physics,
        testCase.scrolls
            ? isA<ClampingScrollPhysics>()
            : isA<NeverScrollableScrollPhysics>(),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('enables scrolling when the OTP keyboard is visible', (
    tester,
  ) async {
    await _pumpVerifyEmail(tester, surfaceSize: const Size(430, 850));
    expect(
      tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('fixed_auth_page_scroll')),
          )
          .physics,
      isA<NeverScrollableScrollPhysics>(),
    );

    final editableFinder = find.descendant(
      of: find.byKey(const ValueKey('otp_code_field')),
      matching: find.byType(EditableText),
    );
    await tester.showKeyboard(find.byKey(const ValueKey('otp_code_field')));
    await tester.pump();
    final focusNode = tester.widget<EditableText>(editableFinder).focusNode;
    expect(focusNode.hasFocus, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    final keyboardScroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('fixed_auth_page_scroll')),
    );
    expect(keyboardScroll.physics, isA<ClampingScrollPhysics>());
    expect(
      keyboardScroll.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.manual,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(AuthTopBar)),
      kind: PointerDeviceKind.unknown,
    );
    await gesture.moveBy(const Offset(0, -100));
    await gesture.up();
    await tester.pump();
    expect(
      tester.widget<EditableText>(editableFinder).focusNode,
      same(focusNode),
    );
    expect(focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirm button is disabled before six digits', (tester) async {
    await _pumpVerifyEmail(tester);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('resend shows loading and disables repeated taps', (
    tester,
  ) async {
    final completer = Completer<ApiResult<OtpDeliveryResult>>();
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

    completer.complete(
      const ApiResult.success(OtpDeliveryResult(resendAfterSeconds: 30)),
    );
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
    expect(find.text('Resend in 00:30'), findsOneWidget);
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
  Size surfaceSize = const Size(430, 850),
  FakeViewPadding viewPadding = FakeViewPadding.zero,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.view.padding = viewPadding;
  addTearDown(tester.view.resetPadding);
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
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppTranslations.supportedLocales,
        locale: const Locale('en'),
        home: const VerifyEmailView(email: 'manual@example.com'),
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
