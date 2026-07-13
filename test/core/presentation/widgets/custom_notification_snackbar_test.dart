import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/constants/app_colors.dart';
import 'package:yalla_market/core/presentation/widgets/snackbars/custom_snackbar.dart';
import 'package:yalla_market/core/routing/app_navigator.dart';

void main() {
  testWidgets(
    'global notification snackbar appears on a nested route in green',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: AppNavigator.key,
          scaffoldMessengerKey: AppNavigator.scaffoldMessengerKey,
          home: const Scaffold(body: Text('home route')),
          routes: {
            '/details': (_) => const Scaffold(body: Text('details route')),
          },
        ),
      );

      AppNavigator.key.currentState!.pushNamed('/details');
      await tester.pumpAndSettle();

      CustomSnackBar.showNotification(
        context: AppNavigator.key.currentContext!,
        messenger: AppNavigator.scaffoldMessengerKey.currentState!,
        title: 'عرض جديد',
        message: 'افتح العرض قبل ما يخلص',
      );
      await tester.pump();

      expect(find.text('details route'), findsOneWidget);
      expect(find.text('عرض جديد'), findsOneWidget);
      expect(find.text('افتح العرض قبل ما يخلص'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).color == AppColors.success,
        ),
        findsOneWidget,
      );
    },
  );
}
