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

  testWidgets('remember me is unchecked and sends temporary mode by default', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpLogin(tester, repository);

    expect(
      tester.widget<WarningCheckbox>(find.byType(WarningCheckbox)).value,
      isFalse,
    );
    await _submitLogin(tester);

    expect(repository.loginCalls, 1);
    expect(repository.lastLoginEmail, 'm@example.com');
    expect(repository.lastRememberMe, isFalse);
  });

  testWidgets('checked remember me reaches the real login request', (
    tester,
  ) async {
    final repository = FakeAuthRepository();
    await _pumpLogin(tester, repository);

    await tester.tap(find.text('Remember Me'));
    await tester.pump();
    expect(
      tester.widget<WarningCheckbox>(find.byType(WarningCheckbox)).value,
      isTrue,
    );
    await _submitLogin(tester);

    expect(repository.loginCalls, 1);
    expect(repository.lastRememberMe, isTrue);
  });
}

Future<void> _pumpLogin(
  WidgetTester tester,
  FakeAuthRepository repository,
) async {
  await tester.binding.setSurfaceSize(const Size(430, 900));
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
