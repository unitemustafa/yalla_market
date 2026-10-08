import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/localization/app_language_controller.dart';
import 'package:yalla_market/core/localization/app_translations.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/views/login_view.dart';
import 'package:yalla_market/features/auth/domain/entities/social_auth_result.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_session.dart';
import 'package:yalla_market/features/auth/presentation/widgets/warning_checkbox.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/app_media/domain/app_media.dart';
import 'package:yalla_market/features/app_media/domain/app_media_repository.dart';
import 'package:yalla_market/features/app_media/domain/load_app_media.dart';
import 'package:yalla_market/features/app_media/presentation/app_media_cubit.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';

import '../../../../helpers/auth_widget_fakes.dart';
import '../../../../helpers/domain_fixtures.dart';

void main() {
  setUp(() {
    AppLanguageController.instance.value = AppLanguage.english;
  });

  testWidgets('Facebook without email asks for one before OTP verification', (
    tester,
  ) async {
    final repository = _EmailLessFacebookRepository();
    await _pumpLogin(tester, repository);
    await tester.ensureVisible(find.text('Facebook'));
    await tester.tap(find.text('Facebook'));
    await tester.pumpAndSettle();
    expect(find.text(AppTranslations.current.verifyEmailTitle), findsOneWidget);
    expect(find.text('Complete your account'), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      findsOneWidget,
    );
    Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(repository.submittedEmail, isNull);
    expect(find.text('This field is required'), findsOneWidget);
    await tester.enterText(
      field(AppTranslations.current.email),
      sampleUser.email,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(repository.submittedEmail, sampleUser.email);
    expect(repository.deferredProfile, isTrue);
    expect(find.text('/verify-email|${sampleUser.email}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provider email goes straight to OTP without a profile form', (
    tester,
  ) async {
    final repository = _EmailLessFacebookRepository(
      providerEmail: sampleUser.email,
    );
    await _pumpLogin(tester, repository);
    await tester.ensureVisible(find.text('Facebook'));
    await tester.tap(find.text('Facebook'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(repository.deferredProfile, isTrue);
    expect(repository.submittedEmail, isNull);
    expect(find.text('/verify-email|${sampleUser.email}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('old login artwork stays hidden until media settings resolve', (
    tester,
  ) async {
    await _pumpLogin(tester, FakeAuthRepository());
    final artwork = find.byWidgetPredicate(
      (widget) =>
          widget is AppImage && widget.source == AppAssets.authMarketHeader,
    );
    expect(artwork, findsNothing);
    final mediaCubit = tester
        .element(find.byType(LoginView))
        .read<AppMediaCubit>();
    await mediaCubit.load();
    await tester.pump();
    expect(artwork, findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);
  });

  for (final rememberMe in [true, false]) {
    testWidgets(
      'Facebook button uses Facebook provider with remember me $rememberMe',
      (tester) async {
        final repository = _FacebookLoginRepository();
        await _pumpLogin(tester, repository);
        expect(find.text('Facebook'), findsOneWidget);
        expect(find.text('Apple'), findsNothing);
        if (!rememberMe) {
          await tester.tap(find.text('Remember Me'));
          await tester.pump();
        }
        final facebook = find.text('Facebook');
        await tester.ensureVisible(facebook);
        await tester.tap(facebook);
        await tester.pump();

        expect(repository.socialCalls, 1);
        expect(repository.lastProvider, SocialAuthProvider.facebook);
        expect(repository.lastSocialRememberMe, rememberMe);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('unverified login opens the verification route automatically', (
    tester,
  ) async {
    final repository = FakeAuthRepository(
      loginFailure: const EmailVerificationRequiredFailure(
        email: 'pending@example.com',
        retryAfterSeconds: 30,
      ),
    );
    await _pumpLogin(tester, repository);

    await _submitLogin(tester);

    expect(find.text('/verify-email|pending@example.com'), findsOneWidget);
  });

  testWidgets(
    'does not show language switcher and displays Google logo button',
    (tester) async {
      await _pumpLogin(tester, FakeAuthRepository());
      expect(
        find.byKey(const ValueKey('login_language_switcher')),
        findsNothing,
      );

      final googleLogoFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == AppAssets.googleLogo,
      );
      expect(googleLogoFinder, findsOneWidget);

      await tester.showKeyboard(find.byType(TextFormField).first);
      await tester.pump();
      final editableFinder = find.byType(EditableText).first;
      final focusNode = tester.widget<EditableText>(editableFinder).focusNode;
      expect(focusNode.hasFocus, isTrue);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

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
    },
  );
}

class _EmailLessFacebookRepository extends FakeAuthRepository {
  _EmailLessFacebookRepository({this.providerEmail = ''});
  final String providerEmail;
  String? submittedEmail;
  bool? deferredProfile;

  @override
  Future<ApiResult<SocialAuthResult>> socialSignIn({
    required SocialAuthProvider provider,
    bool rememberMe = false,
  }) async {
    return ApiResult.success(
      SocialAuthResult(
        action: SocialAuthAction.completeProfile,
        provider: SocialAuthProvider.facebook,
        email: providerEmail,
        firstName: 'Social',
        lastName: 'Customer',
      ),
    );
  }

  @override
  Future<ApiResult<AuthSession>> completeSocialSignup({
    String? email,
    String firstName = '',
    String lastName = '',
    String username = '',
    String phone = '',
    String city = '',
    bool rememberMe = false,
    bool deferProfile = false,
  }) async {
    submittedEmail = email;
    deferredProfile = deferProfile;
    return const ApiResult.success(AuthSession(user: sampleUser));
  }
}

class _FacebookLoginRepository extends FakeAuthRepository {
  int socialCalls = 0;
  SocialAuthProvider? lastProvider;
  bool? lastSocialRememberMe;

  @override
  Future<ApiResult<SocialAuthResult>> socialSignIn({
    required SocialAuthProvider provider,
    bool rememberMe = false,
  }) async {
    socialCalls++;
    lastProvider = provider;
    lastSocialRememberMe = rememberMe;
    return const ApiResult.failure(ValidationFailure('Test sign-in failure.'));
  }
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
        BlocProvider(
          create: (_) =>
              AppMediaCubit(LoadAppMedia(_EmptyAppMediaRepository())),
        ),
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
          builder: (_) => Text('${settings.name}|${settings.arguments}'),
        ),
        home: const LoginView(),
      ),
    ),
  );
}

class _EmptyAppMediaRepository implements AppMediaRepository {
  @override
  Future<ApiResult<AppMedia>> load() async =>
      const ApiResult.success(AppMedia());
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
