import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/errors/failure.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:yalla_market/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:yalla_market/features/onboarding/presentation/cubit/onboarding_cubit.dart';

void main() {
  group('OnboardingCubit', () {
    test(
      'hasSeenOnboarding returns true and updates state on success',
      () async {
        final cubit = OnboardingCubit(
          _useCases(_FakeOnboardingRepository(hasSeenResult: true)),
        );
        final expectedStates = expectLater(cubit.stream, emits(true));

        final seen = await cubit.hasSeenOnboarding();

        expect(seen, isTrue);
        expect(cubit.state, isTrue);
        await expectedStates;
        await cubit.close();
      },
    );

    test('hasSeenOnboarding returns false when repository fails', () async {
      final cubit = OnboardingCubit(
        _useCases(_FakeOnboardingRepository(failHasSeen: true)),
      );

      final seen = await cubit.hasSeenOnboarding();

      expect(seen, isFalse);
      expect(cubit.state, isFalse);
      await cubit.close();
    });

    test(
      'markOnboardingSeen returns true and updates state on success',
      () async {
        final cubit = OnboardingCubit(
          _useCases(_FakeOnboardingRepository(markSeenResult: true)),
        );
        final expectedStates = expectLater(cubit.stream, emits(true));

        final saved = await cubit.markOnboardingSeen();

        expect(saved, isTrue);
        expect(cubit.state, isTrue);
        await expectedStates;
        await cubit.close();
      },
    );

    test(
      'markOnboardingSeen returns false and does not change state to true on failure',
      () async {
        final cubit = OnboardingCubit(
          _useCases(_FakeOnboardingRepository(failMarkSeen: true)),
        );

        final saved = await cubit.markOnboardingSeen();

        expect(saved, isFalse);
        expect(cubit.state, isFalse);
        await cubit.close();
      },
    );
  });
}

OnboardingUseCases _useCases(OnboardingRepository repository) {
  return OnboardingUseCases(
    hasSeenOnboarding: HasSeenOnboardingUseCase(repository),
    markOnboardingSeen: MarkOnboardingSeenUseCase(repository),
  );
}

class _FakeOnboardingRepository implements OnboardingRepository {
  const _FakeOnboardingRepository({
    this.hasSeenResult = false,
    this.markSeenResult = true,
    this.failHasSeen = false,
    this.failMarkSeen = false,
  });

  final bool hasSeenResult;
  final bool markSeenResult;
  final bool failHasSeen;
  final bool failMarkSeen;

  @override
  Future<ApiResult<bool>> hasSeenOnboarding() async {
    if (failHasSeen) {
      return const ApiResult.failure(
        UnknownFailure('Could not load onboarding state.'),
      );
    }
    return ApiResult.success(hasSeenResult);
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
