import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/routing/app_routes.dart';
import 'package:yalla_market/core/theme/app_theme.dart';
import 'package:yalla_market/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:yalla_market/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:yalla_market/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:yalla_market/features/onboarding/presentation/views/onboarding_view.dart';

void main() {
  setUp(() {
    AppLanguageController.instance.value = AppLanguage.arabic;
  });

  testWidgets('navigates to login when onboarding state is saved', (
    tester,
  ) async {
    AppLanguageController.instance.value = AppLanguage.english;
    await tester.pumpWidget(
      _TestApp(repository: _FakeOnboardingRepository(markSeenResult: true)),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets(
    'rebuilds localized onboarding failure and enables retry after saving fails',
    (tester) async {
      await tester.pumpWidget(
        _TestApp(repository: _FakeOnboardingRepository(failMarkSeen: true)),
      );

      expect(find.text('تخطي'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'تخطي'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsNothing);
      expect(find.text('مش قادرين نكمّل'), findsOneWidget);
      expect(find.text('حاول تاني.'), findsOneWidget);
      _expectSkipEnabled(tester, 'تخطي');

      AppLanguageController.instance.value = AppLanguage.english;
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsNothing);
      expect(find.text('Could not continue'), findsOneWidget);
      expect(find.text('Please try again.'), findsOneWidget);
      _expectSkipEnabled(tester, 'Skip');
    },
  );
}

void _expectSkipEnabled(WidgetTester tester, String label) {
  final skipButton = tester.widget<TextButton>(
    find.widgetWithText(TextButton, label),
  );
  expect(skipButton.onPressed, isNotNull);
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.repository});

  final OnboardingRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(_useCases(repository)),
      child: ValueListenableBuilder<AppLanguage>(
        valueListenable: AppLanguageController.instance,
        builder: (context, language, _) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            locale: language.locale,
            supportedLocales: AppTranslations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            home: const OnboardingView(),
            routes: {
              AppRoutes.login: (_) =>
                  const Scaffold(body: Center(child: Text('Login'))),
            },
          );
        },
      ),
    );
  }
}

OnboardingUseCases _useCases(OnboardingRepository repository) {
  return OnboardingUseCases(
    hasSeenOnboarding: HasSeenOnboardingUseCase(repository),
    markOnboardingSeen: MarkOnboardingSeenUseCase(repository),
  );
}

class _FakeOnboardingRepository implements OnboardingRepository {
  const _FakeOnboardingRepository({
    this.markSeenResult = true,
    this.failMarkSeen = false,
  });

  final bool markSeenResult;
  final bool failMarkSeen;

  @override
  Future<ApiResult<bool>> hasSeenOnboarding() async {
    return const ApiResult.success(false);
  }

  @override
  Future<ApiResult<bool>> markOnboardingSeen() async {
    if (failMarkSeen) {
      return const ApiResult.failure(
        UnknownFailure('Could not save onboarding state.'),
      );
    }
    return ApiResult.success(markSeenResult);
  }
}
