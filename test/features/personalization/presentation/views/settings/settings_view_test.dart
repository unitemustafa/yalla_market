import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/preferences/app_preferences_controller.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/features/personalization/presentation/views/settings/app_preferences_view.dart';
import 'package:yalla_market/features/personalization/presentation/views/settings/settings_view.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';

import '../../../../../helpers/auth_widget_fakes.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_user.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_session.dart';
import 'package:yalla_market/features/personalization/presentation/controllers/user_profile_controller.dart';
import 'package:yalla_market/features/personalization/presentation/widgets/profile_completion_floating_button.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppPreferencesController.instance.value = const AppPreferences();
  });

  testWidgets('settings keeps order entry without loading order history', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsView()));

    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('My Cart'), findsOneWidget);
    expect(find.text('My Addresses'), findsOneWidget);
    expect(find.text('Orders'), findsNothing);
    expect(find.text('-'), findsNothing);
  });

  testWidgets('settings fits a compact iPhone viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: SettingsView()));
    await tester.pump();

    expect(find.text('My Orders'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('about and partner entries are merged below account entries', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsView()));

    expect(find.text('About the app'), findsOneWidget);
    expect(find.text('Register as a partner'), findsOneWidget);
    expect(find.text('Support chat'), findsNothing);
    expect(find.text('App Settings'), findsNothing);
    expect(find.text('Account Settings'), findsOneWidget);
  });

  testWidgets('account page shows WhatsApp floating action button', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsView()));

    final button = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(button.tooltip, 'WhatsApp');
    expect(find.byType(FaIcon), findsOneWidget);
  });

  testWidgets('delete account requires password confirmation', (tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthCubit(authUseCases(FakeAuthRepository())),
        child: const MaterialApp(home: SettingsView()),
      ),
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete account permanently?'), findsOneWidget);
    expect(find.byKey(const Key('delete-account-password')), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pump();

    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('about option opens the dedicated about page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          AppRoutes.aboutApp: (_) =>
              const Scaffold(body: Text('Dedicated about page')),
        },
        home: const SettingsView(),
      ),
    );

    await tester.tap(find.text('About the app'));
    await tester.pumpAndSettle();

    expect(find.text('Dedicated about page'), findsOneWidget);
  });

  for (final failure in <Failure>[
    const NetworkFailure('Could not delete your account.'),
    const ValidationFailure('Your account has an active order.'),
  ]) {
    testWidgets('social deletion displays failure: ${failure.message}', (
      tester,
    ) async {
      const user = AuthUser(
        id: 'social-user',
        email: 'social@example.com',
        firstName: 'Social',
        lastName: 'User',
        role: 'client',
        hasPassword: false,
      );
      UserProfileController.instance.updateFromAuthUser(user);
      addTearDown(UserProfileController.instance.reset);
      final repository = _FailedDeletionRepository(failure);
      final cubit = AuthCubit(authUseCases(repository))
        ..hydrate(const AuthSession(user: user));
      addTearDown(cubit.close);

      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(home: SettingsView()),
        ),
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('delete-account-password')), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          failure.message.contains('active order')
              ? 'Finish or cancel any active orders first.'
              : failure.message,
        ),
        findsOneWidget,
      );
      expect(repository.password, isEmpty);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();
    });
  }

  testWidgets('settings tooltip is translated in Arabic', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: AppTranslations.supportedLocales,
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SettingsView(),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message == 'تفضيلات التطبيق',
      ),
      findsOneWidget,
    );
  });

  testWidgets('app preferences shows readonly EGP currency', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppPreferencesView()));

    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('EGP'), findsOneWidget);
    expect(find.text('Egyptian Pound'), findsNothing);
  });

  testWidgets('app preferences switches use local controller state', (
    tester,
  ) async {
    await AppPreferencesController.instance.loadSavedPreferences();

    await tester.pumpWidget(const MaterialApp(home: AppPreferencesView()));

    expect(find.text('Mobile Notifications'), findsOneWidget);
    expect(find.text('Safe Mode'), findsOneWidget);
    expect(
      AppPreferencesController.instance.value.mobileNotificationsEnabled,
      isTrue,
    );
    expect(AppPreferencesController.instance.value.safeModeEnabled, isFalse);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(
      AppPreferencesController.instance.value.mobileNotificationsEnabled,
      isFalse,
    );
    expect(AppPreferencesController.instance.value.safeModeEnabled, isTrue);

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(
        AppPreferencesController.mobileNotificationsStorageKey,
      ),
      isFalse,
    );
    expect(
      preferences.getBool(AppPreferencesController.safeModeStorageKey),
      isTrue,
    );
  });

  testWidgets(
    'account page shows circular completion badge over hero rectangle when profile incomplete',
    (tester) async {
      UserProfileController.instance.updateFromAuthUser(
        const AuthUser(
          id: '1',
          email: 'user@example.com',
          firstName: 'John',
          lastName: 'Doe',
          role: 'client',
          username: 'johndoe',
          profileUsernamePending: true,
        ),
      );
      addTearDown(UserProfileController.instance.reset);

      await tester.pumpWidget(const MaterialApp(home: SettingsView()));

      expect(find.byType(ProfileCompletionFloatingButton), findsOneWidget);
      expect(find.text('29%'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    },
  );
}

class _FailedDeletionRepository extends FakeAuthRepository {
  _FailedDeletionRepository(this.failure);

  final Failure failure;
  String? password;

  @override
  Future<ApiResult<bool>> deleteAccount({required String password}) async {
    this.password = password;
    return ApiResult.failure(failure);
  }
}
