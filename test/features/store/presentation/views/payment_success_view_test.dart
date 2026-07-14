import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:yalla_market/core/routing/app_route_arguments.dart';
import 'package:yalla_market/features/store/presentation/views/checkout/payment_success_view.dart';

void main() {
  testWidgets(
    'uses an animated success scene, plays feedback once, and fits compact screens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var feedbackCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: PaymentSuccessView(
            args: const PaymentSuccessRouteArgs(
              orderId: '7',
              status: 'Pending',
              reviewStatus: 'Awaiting review',
              total: 'EGP 50',
              marketCount: 1,
              marketSummary: 'Test market',
              isMultiMarket: false,
              marketSections: [],
            ),
            feedbackPlayer: () async {
              feedbackCalls++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('payment_success_animation')),
        findsOneWidget,
      );
      expect(find.byType(AppImage), findsNothing);
      expect(find.text('Order confirmed'), findsOneWidget);
      expect(feedbackCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion shows the completed scene without replaying feedback',
    (tester) async {
      var feedbackCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: PaymentSuccessView(
              feedbackPlayer: () async {
                feedbackCalls++;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(
        find.byKey(const ValueKey('payment_success_animation')),
        findsOneWidget,
      );
      expect(feedbackCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
