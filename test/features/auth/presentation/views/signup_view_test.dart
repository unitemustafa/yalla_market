import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/views/signup_view.dart';

import '../../../../helpers/auth_widget_fakes.dart';

void main() {
  setUp(() {
    AppLanguageController.instance.value = AppLanguage.english;
  });

  testWidgets('keeps the policy agreement on one line on a narrow screen', (
    tester,
  ) async {
    await _pumpSignup(tester, surfaceSize: const Size(320, 900));

    final policyLine = find.byKey(const ValueKey('signup_policy_single_line'));
    expect(policyLine, findsOneWidget);
    expect(tester.widget<FittedBox>(policyLine).fit, BoxFit.scaleDown);
    expect(tester.getSize(policyLine).height, lessThanOrEqualTo(24));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps field focus when the keyboard resizes signup', (
    tester,
  ) async {
    await _pumpSignup(tester, surfaceSize: const Size(360, 700));
    await tester.showKeyboard(find.byType(TextFormField).first);
    await tester.pump();

    final editableFinder = find.byType(EditableText).first;
    final focusNode = tester.widget<EditableText>(editableFinder).focusNode;
    expect(focusNode.hasFocus, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    expect(
      tester.widget<EditableText>(editableFinder).focusNode,
      same(focusNode),
    );
    expect(focusNode.hasFocus, isTrue);
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView).first,
    );
    expect(
      scroll.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.manual,
    );
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -100),
    );
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('required errors clear while typing valid names', (tester) async {
    await _pumpSignup(tester);

    await _tapCreateAccount(tester, 'Create Account');
    await tester.pump();

    expect(find.text('This field is required'), findsWidgets);

    await tester.enterText(_fieldByLabel('First Name'), 'Mustafa');
    await tester.enterText(_fieldByLabel('Last Name'), 'Ali');
    await tester.pump();

    final firstNameField = _textFormField(tester, 'First Name');
    final lastNameField = _textFormField(tester, 'Last Name');
    expect(firstNameField.validator?.call('Mustafa'), isNull);
    expect(lastNameField.validator?.call('Ali'), isNull);
  });

  testWidgets('email validation clears when email becomes valid', (
    tester,
  ) async {
    await _pumpSignup(tester);

    await tester.enterText(_fieldByLabel('E-Mail'), 'not-email');
    await _tapCreateAccount(tester, 'Create Account');
    await tester.pump();

    expect(find.text('Please enter a valid email'), findsOneWidget);

    await tester.enterText(_fieldByLabel('E-Mail'), 'manual@example.com');
    await tester.pump();

    expect(find.text('Please enter a valid email'), findsNothing);
  });

  testWidgets(
    'username accepts digits, blocks spaces, and rejects digits only',
    (tester) async {
      await _pumpSignup(tester);

      expect(
        _textFormField(tester, 'Username').validator?.call('manual#'),
        'Use English letters, numbers, dots, and underscores only',
      );

      await tester.enterText(_fieldByLabel('Username'), 'manual2026');
      await tester.pump();

      expect(
        find.text('Use English letters, numbers, dots, and underscores only'),
        findsNothing,
      );

      await tester.enterText(_fieldByLabel('Username'), 'manual 2026');
      await tester.pump();
      expect(
        tester
            .widget<TextFormField>(_fieldByLabel('Username'))
            .controller
            ?.text,
        'manual2026',
      );

      await tester.enterText(_fieldByLabel('Username'), '2026');
      await tester.pump();
      expect(
        _textFormField(tester, 'Username').validator?.call('2026'),
        'Username must include a letter',
      );
    },
  );

  testWidgets('availability success does not appear with validation error', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpSignup(tester, repository: repository);

    await tester.showKeyboard(_fieldByLabel('Username'));
    await tester.pump();
    await tester.enterText(_fieldByLabel('Username'), 'manual2026');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(repository.usernameChecks, 1);
    expect(find.text('Username must include a letter'), findsNothing);

    await tester.enterText(_fieldByLabel('Username'), '2026');
    await tester.pump();

    expect(
      find.byKey(const ValueKey('availability_success_icon')),
      findsNothing,
    );
    expect(find.text('Username must include a letter'), findsOneWidget);
  });

  testWidgets('email availability runs once until normalized value changes', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpSignup(tester, repository: repository);

    await tester.showKeyboard(_fieldByLabel('E-Mail'));
    await tester.enterText(_fieldByLabel('E-Mail'), ' Manual@Example.COM ');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    expect(repository.emailChecks, 1);

    await tester.showKeyboard(_fieldByLabel('First Name'));
    await tester.pump();
    await tester.showKeyboard(_fieldByLabel('E-Mail'));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    expect(repository.emailChecks, 1);

    await tester.pumpWidget(
      BlocProvider.value(
        value: BlocProvider.of<AuthCubit>(
          tester.element(find.byType(SignupView)),
        ),
        child: _signupApp(const SignupView()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));

    expect(repository.emailChecks, 1);

    await tester.enterText(_fieldByLabel('E-Mail'), 'other@example.com');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    expect(repository.emailChecks, 2);
  });

  testWidgets('stale availability response does not overwrite newer value', (
    tester,
  ) async {
    final first = Completer<ApiResult<bool>>();
    final second = Completer<ApiResult<bool>>();
    final repository = FakeAuthRepository(
      emailCheckCompleters: [first, second],
    );
    await _pumpSignup(tester, repository: repository);

    await tester.showKeyboard(_fieldByLabel('E-Mail'));
    await tester.enterText(_fieldByLabel('E-Mail'), 'first@example.com');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();
    await tester.enterText(_fieldByLabel('E-Mail'), 'second@example.com');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    expect(repository.emailChecks, 2);

    first.complete(const ApiResult.success(true));
    await tester.pump();

    expect(find.text('This email is already registered.'), findsNothing);

    second.complete(const ApiResult.success(false));
    await tester.pump();

    expect(find.text('Could not check this email.'), findsNothing);
    expect(find.text('This email is already registered.'), findsNothing);
  });

  testWidgets(
    'network failure is shown as unknown, then clears after success',
    (tester) async {
      final first = Completer<ApiResult<bool>>();
      final second = Completer<ApiResult<bool>>();
      final repository = FakeAuthRepository(
        emailCheckCompleters: [first, second],
      );
      await _pumpSignup(tester, repository: repository);

      await tester.showKeyboard(_fieldByLabel('E-Mail'));
      await tester.enterText(_fieldByLabel('E-Mail'), 'down@example.com');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();

      first.complete(const ApiResult.failure(NetworkFailure('Network down')));
      await tester.pump();

      expect(find.text('Could not check this email.'), findsOneWidget);
      expect(find.text('This email is already registered.'), findsNothing);

      await tester.enterText(_fieldByLabel('E-Mail'), 'up@example.com');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();

      second.complete(const ApiResult.success(false));
      await tester.pump();

      expect(find.text('Could not check this email.'), findsNothing);
      expect(find.text('This email is already registered.'), findsNothing);
    },
  );

  testWidgets('phone availability failure is not treated as registered', (
    tester,
  ) async {
    final completer = Completer<ApiResult<bool>>();
    final repository = FakeAuthRepository(phoneCheckCompleters: [completer]);
    await _pumpSignup(tester, repository: repository);

    await tester.showKeyboard(_fieldByLabel('Phone Number'));
    await tester.enterText(_fieldByLabel('Phone Number'), '01000000000');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    completer.complete(const ApiResult.failure(NetworkFailure('Network down')));
    await tester.pump();

    expect(repository.phoneChecks, 1);
    expect(find.text('Could not check this phone number.'), findsOneWidget);
    expect(find.text('This phone number is already registered.'), findsNothing);
  });

  testWidgets('phone field uses the same input text color as other fields', (
    tester,
  ) async {
    await _pumpSignup(tester);

    final emailTextField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'E-Mail'),
    );
    final phoneTextField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Phone Number'),
    );

    expect(phoneTextField.style?.color, emailTextField.style?.color);
    expect(phoneTextField.decoration?.hintText, '01xxxxxxxxx');
  });

  testWidgets('validation messages follow app language', (tester) async {
    await _pumpSignup(tester, locale: const Locale('ar'));

    await _tapCreateAccount(tester, 'اعمل حساب جديد');
    await tester.pump();

    expect(find.text('الخانة دي مطلوبة'), findsWidgets);

    AppLanguageController.instance.value = AppLanguage.english;
    await _pumpSignup(tester, locale: const Locale('en'));

    await _tapCreateAccount(tester, 'Create Account');
    await tester.pump();

    expect(find.text('This field is required'), findsWidgets);
  });
}

Finder _fieldByLabel(String label) {
  return find.widgetWithText(TextFormField, label);
}

TextFormField _textFormField(WidgetTester tester, String label) {
  return tester.widget<TextFormField>(_fieldByLabel(label));
}

Future<void> _tapCreateAccount(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _pumpSignup(
  WidgetTester tester, {
  FakeAuthRepository? repository,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(430, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  AppLanguageController.instance.value = AppLanguage.fromCode(
    locale.languageCode,
  );
  final authCubit = AuthCubit(authUseCases(repository ?? FakeAuthRepository()));
  addTearDown(authCubit.close);

  await tester.pumpWidget(
    BlocProvider.value(
      value: authCubit,
      child: _signupApp(const SignupView(), locale: locale),
    ),
  );
}

Widget _signupApp(Widget home, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppTranslations.supportedLocales,
    locale: locale,
    home: home,
  );
}
