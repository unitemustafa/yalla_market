import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/core/presentation/widgets/states/app_skeleton.dart';
import 'package:yalla_market/features/auth/domain/entities/auth_user.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/personalization/presentation/controllers/user_profile_controller.dart';
import 'package:yalla_market/features/personalization/presentation/views/profile/profile_view.dart';

import '../../../../../helpers/auth_widget_fakes.dart';
import '../../../../../helpers/domain_fixtures.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserProfileController.instance.updateFromAuthUser(sampleUser);
  });

  tearDown(() => UserProfileController.instance.reset());

  for (final brightness in Brightness.values) {
    testWidgets(
      'profile content stays still after entry refresh in $brightness',
      (tester) async {
        final repository = _PendingProfileRepository();
        final cubit = AuthCubit(authUseCases(repository));
        addTearDown(cubit.close);
        await cubit.login(email: sampleUser.email, password: 'test-password');

        await tester.pumpWidget(
          BlocProvider.value(
            value: cubit,
            child: MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: const ProfileView(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(AppLoadingPlaceholder), findsOneWidget);
        final namePosition = tester.getTopLeft(find.text('Mustafa Ali').first);
        final sectionPosition = tester.getTopLeft(
          find.text('Profile Information'),
        );

        repository.profile.complete(const ApiResult.success(sampleUser));
        await tester.pump();
        await tester.pump();

        expect(find.byType(AppLoadingPlaceholder), findsNothing);
        expect(tester.getTopLeft(find.text('Mustafa Ali').first), namePosition);
        expect(
          tester.getTopLeft(find.text('Profile Information')),
          sectionPosition,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _PendingProfileRepository extends FakeAuthRepository {
  final profile = Completer<ApiResult<AuthUser>>();

  @override
  Future<ApiResult<AuthUser>> me() => profile.future;
}
