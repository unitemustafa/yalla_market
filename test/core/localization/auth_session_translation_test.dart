import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/core/localization/app_translations.dart';

const _unverifiedEmailMessage = 'Account email has not been verified.';
const _offlineMessage = 'No internet connection.';
const _offlineBannerMessage =
    'No internet connection. Check your network to continue updates.';
const _sessionExpiredMessage =
    'Sign in again to continue. Remember Me keeps you signed in after closing the app.';
const _oldSessionExpiredMessage =
    'Sign in again to continue. Remember Me keeps you signed in for 30 days after closing the app. Without it, your session lasts up to 8 hours and ends when the app closes.';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLanguageController.instance.value = AppLanguage.arabic;
  });

  group('auth and session display translations', () {
    test('translates backend auth and network messages in Arabic', () {
      final translations = AppTranslations.current;

      expect(
        translations.phrase(_unverifiedEmailMessage),
        'الإيميل لسه ما اتفعّلش.',
      );
      expect(translations.phrase(_offlineMessage), 'مفيش اتصال بالإنترنت.');
      expect(
        translations.phrase('No internet connection'),
        'مفيش اتصال بالإنترنت.',
      );
      expect(
        translations.phrase(_offlineBannerMessage),
        'مفيش اتصال بالإنترنت. راجع الشبكة عشان نحدّث البيانات.',
      );
      expect(
        translations.phrase(_sessionExpiredMessage),
        'سجّل دخول تاني عشان تكمل. «افتكرني» بتحافظ على تسجيل دخولك بعد قفل التطبيق.',
      );
    });

    test('keeps backend auth and network messages in English', () {
      AppLanguageController.instance.value = AppLanguage.english;
      final translations = AppTranslations.current;

      expect(
        translations.phrase(_unverifiedEmailMessage),
        _unverifiedEmailMessage,
      );
      expect(translations.phrase(_offlineMessage), _offlineMessage);
      expect(
        translations.phrase(_sessionExpiredMessage),
        _sessionExpiredMessage,
      );
    });

    testWidgets(
      'updates visible auth and session text after AppLanguageController changes',
      (tester) async {
        await tester.pumpWidget(const _LocalizedHarness());

        expect(find.text('الإيميل لسه ما اتفعّلش.'), findsOneWidget);
        expect(find.text('مفيش اتصال بالإنترنت.'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('show-session-dialog')));
        await tester.pumpAndSettle();

        expect(find.text('انتهت الجلسة'), findsOneWidget);
        expect(
          find.text(
            'سجّل دخول تاني عشان تكمل. «افتكرني» بتحافظ على تسجيل دخولك بعد قفل التطبيق.',
          ),
          findsOneWidget,
        );
        expect(find.text('تسجيل الدخول'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('dismiss-session-dialog')));
        await tester.pumpAndSettle();

        await AppLanguageController.instance.setLanguage(AppLanguage.english);
        await tester.pumpAndSettle();

        expect(find.text(_unverifiedEmailMessage), findsOneWidget);
        expect(find.text(_offlineMessage), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('show-session-dialog')));
        await tester.pumpAndSettle();

        expect(find.text('Session expired'), findsOneWidget);
        expect(find.text(_sessionExpiredMessage), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
      },
    );

    test('does not keep the old long session message in display files', () {
      final appFile = File('lib/yalla_market_app.dart').readAsStringSync();
      final phrasesFile = File(
        'lib/core/localization/app_translation_phrases.dart',
      ).readAsStringSync();

      expect(appFile, isNot(contains(_oldSessionExpiredMessage)));
      expect(phrasesFile, isNot(contains(_oldSessionExpiredMessage)));
    });

    test(
      'does not hardcode Arabic in auth display or error handling files',
      () {
        final arabicCodePoint = RegExp(r'[\u0600-\u06FF]');
        final files = [
          'lib/features/auth/presentation/views/login_view.dart',
          'lib/yalla_market_app.dart',
          'lib/core/errors/api_error_handler.dart',
        ];

        for (final path in files) {
          expect(
            File(path).readAsStringSync(),
            isNot(matches(arabicCodePoint)),
            reason: '$path should translate display strings with context.tr.',
          );
        }
      },
    );
  });
}

class _LocalizedHarness extends StatelessWidget {
  const _LocalizedHarness();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.instance,
      builder: (context, language, _) {
        return MaterialApp(
          locale: language.locale,
          supportedLocales: AppTranslations.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    Text(context.tr(_unverifiedEmailMessage)),
                    Text(context.tr(_offlineMessage)),
                    FilledButton(
                      key: const ValueKey('show-session-dialog'),
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              title: Text(dialogContext.tr('Session expired')),
                              content: Text(
                                dialogContext.tr(_sessionExpiredMessage),
                              ),
                              actions: [
                                TextButton(
                                  key: const ValueKey('dismiss-session-dialog'),
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: Text(dialogContext.tr('Sign In')),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('show'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
