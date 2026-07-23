import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/personalization/domain/entities/partner_application.dart';
import 'package:yalla_market/features/personalization/domain/repositories/partner_application_repository.dart';
import 'package:yalla_market/features/personalization/presentation/views/settings/partner_application_view.dart';

void main() {
  testWidgets('partner application uses Yalla Market form sections', (
    tester,
  ) async {
    final repository = _FakePartnerApplicationRepository();

    await tester.pumpWidget(
      MaterialApp(home: PartnerApplicationView(repository: repository)),
    );

    expect(find.text('Register as a partner'), findsOneWidget);
    expect(find.text('Business information'), findsOneWidget);
    expect(find.text('Contact person'), findsOneWidget);
    expect(find.text('Business name'), findsOneWidget);
    expect(find.text('Number of branches'), findsOneWidget);
    expect(find.text('1 branch'), findsOneWidget);
    expect(find.text('Do you have a trade license?'), findsOneWidget);
  });

  testWidgets('all partner choices use the custom options sheet', (
    tester,
  ) async {
    final repository = _FakePartnerApplicationRepository();

    await tester.pumpWidget(
      MaterialApp(home: PartnerApplicationView(repository: repository)),
    );

    expect(find.byType(DropdownButtonFormField), findsNothing);
    expect(
      find.byKey(const ValueKey('partner-picker-Business type')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('partner-picker-Business type')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('partner-options-sheet-Business type')),
      findsOneWidget,
    );
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Restaurant'), findsOneWidget);
    expect(find.text('Service provider'), findsOneWidget);

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('partner-options-sheet-Business type')),
      findsNothing,
    );
    expect(find.text('Shop'), findsOneWidget);
  });

  testWidgets('partner application validates required fields before submit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakePartnerApplicationRepository();

    await tester.pumpWidget(
      MaterialApp(home: PartnerApplicationView(repository: repository)),
    );
    await tester.scrollUntilVisible(
      find.text('Submit application'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Submit application'));
    await tester.pump();

    expect(repository.submitCount, 0);
    expect(find.text('This field is required.'), findsWidgets);
  });
}

class _FakePartnerApplicationRepository
    implements PartnerApplicationRepository {
  int submitCount = 0;

  @override
  Future<ApiResult<PartnerApplicationReceipt>> submit(
    PartnerApplicationRequest request,
  ) async {
    submitCount += 1;
    return const ApiResult.success(
      PartnerApplicationReceipt(
        id: '1',
        businessName: 'Test business',
        status: 'pending',
        createdAt: null,
      ),
    );
  }
}
