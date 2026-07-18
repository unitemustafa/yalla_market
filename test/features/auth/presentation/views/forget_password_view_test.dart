import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/otp/otp_cooldown_store.dart';
import 'package:yalla_market/core/routing/app_router.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
import 'package:yalla_market/features/auth/domain/entities/otp_delivery_result.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/views/forget_password_view.dart';
import 'package:yalla_market/features/auth/presentation/widgets/auth_top_bar.dart';

import '../../../../helpers/auth_widget_fakes.dart';

void main() {
  const cooldownStore = OtpCooldownStore();
  const registeredEmail = 'manual@example.com';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLanguageController.instance.value = AppLanguage.english;
  });

  testWidgets('uses a fixed layout and the same back button as signup', (
    tester,
  ) async {
    for (final size in const [Size(320, 480), Size(360, 600), Size(600, 900)]) {
      await _pumpForgetPassword(
        tester,
        repository: FakeAuthRepository(),
        surfaceSize: size,
        textScale: size.height == 480 ? 1.5 : 1,
      );

      final fixedScroll = tester.widget<SingleChildScrollView>(
        find.byKey(const ValueKey('fixed_auth_page_scroll')),
      );
      expect(fixedScroll.physics, isA<NeverScrollableScrollPhysics>());
      final topBar = tester.widget<AuthTopBar>(find.byType(AuthTopBar));
      expect(topBar.showBack, isTrue);
      expect(topBar.showClose, isFalse);
      final artwork = tester.widget<Container>(
        find.byKey(const ValueKey('auth_lock_artwork')),
      );
      expect(artwork.constraints?.maxWidth, 58);
      expect(artwork.constraints?.maxHeight, 58);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('enables scrolling only while the keyboard is visible', (
    tester,
  ) async {
    await _pumpForgetPassword(
      tester,
      repository: FakeAuthRepository(),
      surfaceSize: const Size(360, 600),
    );
    expect(
      tester
          .widget<SingleChildScrollView>(
            find.byKey(const ValueKey('fixed_auth_page_scroll')),
          )
          .physics,
      isA<NeverScrollableScrollPhysics>(),
    );

    await tester.showKeyboard(find.byType(TextFormField).first);
    await tester.pump();
    final editableFinder = find.byType(EditableText).first;
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
    await tester.drag(
      find.byKey(const ValueKey('fixed_auth_page_scroll')),
      const Offset(0, -80),
    );
    await tester.pump();
    expect(
      tester.widget<EditableText>(editableFinder).focusNode,
      same(focusNode),
    );
    expect(focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without cooldown shows Send button', (tester) async {
    await _pumpForgetPassword(
      tester,
      repository: FakeAuthRepository(registeredEmails: {registeredEmail}),
    );

    await _enterRegisteredEmail(tester, registeredEmail);

    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Enter'), findsNothing);
    expect(find.textContaining('Resend available in'), findsNothing);
  });

  testWidgets('with active cooldown shows Enter and remaining time', (
    tester,
  ) async {
    await cooldownStore.save(
      purpose: OtpPurpose.passwordReset,
      identifier: registeredEmail,
      seconds: 30,
    );
    await _pumpForgetPassword(
      tester,
      repository: FakeAuthRepository(registeredEmails: {registeredEmail}),
    );

    await _enterRegisteredEmail(tester, registeredEmail);

    expect(find.text('Enter'), findsOneWidget);
    expect(
      find.textContaining('You can use the code already sent to your email.'),
      findsOneWidget,
    );
    expect(find.textContaining('Resend available in 00:'), findsOneWidget);
    expect(_primaryButton(tester).onPressed, isNotNull);
  });

  testWidgets('Enter during cooldown navigates without requesting reset', (
    tester,
  ) async {
    final repository = FakeAuthRepository(registeredEmails: {registeredEmail});
    final observer = _RecordingNavigatorObserver();
    await cooldownStore.save(
      purpose: OtpPurpose.passwordReset,
      identifier: registeredEmail,
      seconds: 30,
    );
    await _pumpForgetPassword(
      tester,
      repository: repository,
      navigatorObservers: [observer],
    );
    await _enterRegisteredEmail(tester, registeredEmail);

    await tester.tap(find.text('Enter'));
    await tester.pump();

    expect(repository.passwordResetRequests, 0);
    expect(observer.pushedRouteNames, contains(AppRoutes.resetPassword));
  });

  testWidgets('cooldown expiry switches button back to Send', (tester) async {
    var currentTime = DateTime(2026, 7, 5, 12);
    DateTime fakeNow() => currentTime;
    final cooldownStore = OtpCooldownStore(now: fakeNow);
    await cooldownStore.save(
      purpose: OtpPurpose.passwordReset,
      identifier: registeredEmail,
      seconds: 2,
    );
    await _pumpForgetPassword(
      tester,
      repository: FakeAuthRepository(registeredEmails: {registeredEmail}),
      cooldownStore: cooldownStore,
      now: fakeNow,
    );
    await _enterRegisteredEmail(tester, registeredEmail);

    final button = find.byKey(const ValueKey('forgot_password_primary_button'));
    expect(button, findsOneWidget);
    expect(
      find.descendant(of: button, matching: find.text('Enter')),
      findsOneWidget,
    );
    expect(find.text('Send'), findsNothing);
    expect(
      find.textContaining('You can use the code already sent to your email.'),
      findsOneWidget,
    );
    expect(find.textContaining('Resend available in'), findsOneWidget);

    currentTime = currentTime.add(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 200));

    expect(button, findsOneWidget);
    expect(
      find.descendant(of: button, matching: find.text('Send')),
      findsOneWidget,
    );
    expect(find.text('Enter'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.textContaining('You can use the code already sent to your email.'),
      findsNothing,
    );
    expect(find.textContaining('Resend available in'), findsNothing);

    final snapshot = await cooldownStore.read(
      purpose: OtpPurpose.passwordReset,
      identifier: registeredEmail,
    );
    expect(snapshot, isNull);
  });

  testWidgets('Send requests reset once, saves cooldown, and navigates', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      registeredEmails: {registeredEmail},
      passwordResetResults: const [OtpDeliveryResult(resendAfterSeconds: 45)],
    );
    final observer = _RecordingNavigatorObserver();
    await _pumpForgetPassword(
      tester,
      repository: repository,
      navigatorObservers: [observer],
    );
    await _enterRegisteredEmail(tester, registeredEmail);

    await tester.tap(find.text('Send'));
    await tester.pump();
    await tester.pump();

    final snapshot = await cooldownStore.read(
      purpose: OtpPurpose.passwordReset,
      identifier: registeredEmail,
    );
    expect(repository.passwordResetRequests, 1);
    expect(snapshot?.resendAfterSeconds, 45);
    expect(observer.pushedRouteNames, contains(AppRoutes.resetPassword));
  });

  testWidgets('HTTP 429 stores cooldown and shows informational Arabic copy', (
    tester,
  ) async {
    AppLanguageController.instance.value = AppLanguage.arabic;
    final repository = FakeAuthRepository(
      registeredEmails: {registeredEmail},
      passwordResetFailure: const OtpCooldownFailure(
        'Please wait before requesting another code.',
        retryAfterSeconds: 30,
      ),
    );
    await _pumpForgetPassword(
      tester,
      repository: repository,
      locale: const Locale('ar'),
    );
    await _enterRegisteredEmail(tester, registeredEmail);

    await tester.tap(find.text('إرسال'));
    await tester.pump();
    await tester.pump();

    final snapshot = await cooldownStore.read(
      purpose: OtpPurpose.passwordReset,
      identifier: registeredEmail,
    );
    expect(snapshot?.resendAfterSeconds, 30);
    expect(find.text('دخول'), findsOneWidget);
    expect(find.text('الكود اتبعت قبل كده'), findsOneWidget);
    expect(
      find.textContaining('تقدر تستخدم الكود اللي اتبعت على بريدك'),
      findsWidgets,
    );
    expect(find.text('Login failed'), findsNothing);
    expect(
      find.text('Please wait before requesting another code.'),
      findsNothing,
    );
  });

  testWidgets('changing email uses independent cooldown state', (tester) async {
    const secondEmail = 'second@example.com';
    await cooldownStore.save(
      purpose: OtpPurpose.passwordReset,
      identifier: registeredEmail,
      seconds: 30,
    );
    await _pumpForgetPassword(
      tester,
      repository: FakeAuthRepository(
        registeredEmails: {registeredEmail, secondEmail},
      ),
    );

    await _enterRegisteredEmail(tester, registeredEmail);
    expect(find.text('Enter'), findsOneWidget);

    await _enterRegisteredEmail(tester, secondEmail);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Enter'), findsNothing);

    await _enterRegisteredEmail(tester, registeredEmail);
    expect(find.text('Enter'), findsOneWidget);
    expect(find.textContaining('Resend available in 00:'), findsOneWidget);
  });

  testWidgets('expired first-email timer does not update second email', (
    tester,
  ) async {
    var currentTime = DateTime(2026, 7, 5, 12);
    DateTime fakeNow() => currentTime;
    final cooldownStore = OtpCooldownStore(now: fakeNow);
    const secondEmail = 'second@example.com';
    await cooldownStore.save(
      purpose: OtpPurpose.passwordReset,
      identifier: registeredEmail,
      seconds: 1,
    );
    await _pumpForgetPassword(
      tester,
      repository: FakeAuthRepository(
        registeredEmails: {registeredEmail, secondEmail},
      ),
      cooldownStore: cooldownStore,
      now: fakeNow,
    );

    await _enterRegisteredEmail(tester, registeredEmail);
    expect(find.text('Enter'), findsOneWidget);

    await _enterRegisteredEmail(tester, secondEmail);
    final primaryButton = find.byKey(
      const ValueKey('forgot_password_primary_button'),
    );
    expect(primaryButton, findsOneWidget);
    expect(
      find.descendant(of: primaryButton, matching: find.text('Send')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: primaryButton, matching: find.text('Enter')),
      findsNothing,
    );

    currentTime = currentTime.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(primaryButton, findsOneWidget);
    expect(
      find.descendant(of: primaryButton, matching: find.text('Send')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: primaryButton, matching: find.text('Enter')),
      findsNothing,
    );
    expect(find.textContaining('Resend available in'), findsNothing);
  });
}

Future<void> _pumpForgetPassword(
  WidgetTester tester, {
  required FakeAuthRepository repository,
  Locale locale = const Locale('en'),
  List<NavigatorObserver> navigatorObservers = const [],
  OtpCooldownStore? cooldownStore,
  DateTime Function()? now,
  Size surfaceSize = const Size(430, 850),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final authCubit = AuthCubit(authUseCases(repository));
  addTearDown(authCubit.close);

  await tester.pumpWidget(
    BlocProvider.value(
      value: authCubit,
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
        locale: locale,
        home: ForgetPasswordView(cooldownStore: cooldownStore, now: now),
        onGenerateRoute: AppRouter.generateRoute,
        navigatorObservers: navigatorObservers,
      ),
    ),
  );
}

Future<void> _enterRegisteredEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField), email);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

ElevatedButton _primaryButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRouteNames = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRouteNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}
