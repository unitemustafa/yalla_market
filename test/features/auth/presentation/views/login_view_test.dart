import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/views/login_view.dart';
import 'package:yalla_market/features/auth/presentation/widgets/warning_checkbox.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';

import '../../../../helpers/auth_widget_fakes.dart';

void main() {
  setUp(() {
    AppLanguageController.instance.value = AppLanguage.english;
  });

  testWidgets('remember me is checked and sends persistent mode by default', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpLogin(tester, repository);

    expect(
      tester.widget<WarningCheckbox>(find.byType(WarningCheckbox)).value,
      isTrue,
    );
    await _submitLogin(tester);

    expect(repository.loginCalls, 1);
    expect(repository.lastLoginEmail, 'm@example.com');
    expect(repository.lastRememberMe, isTrue);
  });

  testWidgets('unchecked remember me reaches the temporary login request', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpLogin(tester, repository);

    await tester.tap(find.text('Remember Me'));
    await tester.pump();
    expect(
      tester.widget<WarningCheckbox>(find.byType(WarningCheckbox)).value,
      isFalse,
    );
    await _submitLogin(tester);

    expect(repository.loginCalls, 1);
    expect(repository.lastRememberMe, isFalse);
  });

  testWidgets('login fits a compact iPhone width with remember me selected', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpLogin(tester, repository, surfaceSize: const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(find.text('Remember Me'), findsOneWidget);
    expect(
      tester.widget<WarningCheckbox>(find.byType(WarningCheckbox)).value,
      isTrue,
    );
  });

  testWidgets('animates language switcher without losing keyboard focus', (
    tester,
  ) async {
    await _pumpLogin(tester, FakeAuthRepository());
    expect(
      find.byKey(const ValueKey('login_language_switcher')),
      findsOneWidget,
    );

    await tester.showKeyboard(find.byType(TextFormField).first);
    await tester.pump();
    final editableFinder = find.byType(EditableText).first;
    final focusNode = tester.widget<EditableText>(editableFinder).focusNode;
    expect(focusNode.hasFocus, isTrue);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('login_language_switcher')),
      findsOneWidget,
    );
    final visibility = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey('login_language_switcher_visibility')),
    );
    expect(visibility.opacity, 0);
    final ignorePointer = tester.widget<IgnorePointer>(
      find
          .ancestor(
            of: find.byKey(
              const ValueKey('login_language_switcher_visibility'),
            ),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(ignorePointer.ignoring, isTrue);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -100),
    );
    await tester.pump();
    expect(
      tester.widget<EditableText>(editableFinder).focusNode,
      same(focusNode),
    );
    expect(focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLogin(
  WidgetTester tester,
  FakeAuthRepository repository, {
  Size surfaceSize = const Size(430, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final authCubit = AuthCubit(authUseCases(repository));
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
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppTranslations.supportedLocales,
        locale: const Locale('en'),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SizedBox.shrink(),
        ),
        home: const LoginView(),
      ),
    ),
  );
}

Future<void> _submitLogin(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'm@example.com');
  await tester.enterText(fields.at(1), 'Password123!');
  final signIn = find.text('Sign In');
  await tester.ensureVisible(signIn);
  await tester.tap(signIn);
  await tester.pump();
  await tester.pump();
}
