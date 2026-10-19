import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yalla_market/app/routing/app_routes.dart';
import 'package:yalla_market/core/icons/app_icons.dart';
import 'package:yalla_market/core/notifications/push_notification_service.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:yalla_market/features/auth/presentation/cubit/auth_state.dart';
import 'package:yalla_market/features/auth/presentation/views/login_view.dart';
import 'package:yalla_market/features/cart/domain/entities/cart_item.dart';
import 'package:yalla_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:yalla_market/features/cart/presentation/views/cart_view.dart';
import 'package:yalla_market/features/location/presentation/cubit/location_cubit.dart';
import 'package:yalla_market/features/navigation/presentation/views/navigation_menu_view.dart';
import 'package:yalla_market/features/store/presentation/cubit/checkout_cubit.dart';
import 'package:yalla_market/features/store/presentation/views/checkout_view.dart';
import 'package:yalla_market/features/store/presentation/views/checkout/payment_success_view.dart';

/// Optional functional review after startup sampling. The fixture is never
/// supplied through a command line, rendered, or included in emitted events.
Future<void> runRequestedReleaseReview(
  WidgetsBinding binding,
  void Function(Map<String, Object?>) emit,
) async {
  await binding.endOfFrame;
  final directory = await getExternalStorageDirectory();
  if (directory == null) {
    return;
  }
  final file = File('${directory.path}/performance.private.json');
  if (!await file.exists()) {
    return;
  }
  var step = 'fixture';
  Element? locate(bool Function(Element) predicate) {
    Element? result;
    void visit(Element element) {
      if (result != null ||
          (element.widget is Offstage &&
              (element.widget as Offstage).offstage)) {
        return;
      }
      if (predicate(element)) {
        result = element;
        return;
      }
      element.visitChildElements(visit);
    }

    binding.rootElement?.visitChildElements(visit);
    return result;
  }

  Future<void> waitFor(bool Function() predicate) async {
    final end = DateTime.now().add(const Duration(seconds: 25));
    while (!predicate() && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!predicate()) {
      throw StateError('Release UI phase timed out');
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    emit({'event': 'release_review', 'step': step, 'status': 'ready'});
  }

  void press(IconData icon, {bool ink = false}) {
    final element = locate(
      (e) =>
          e.widget is Icon &&
          (e.widget as Icon).icon == icon &&
          (ModalRoute.of(e)?.isCurrent ?? true),
    );
    if (element == null) {
      throw StateError('Release UI control missing');
    }
    VoidCallback? callback;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (ink && widget is InkWell) {
        callback = widget.onTap;
      }
      if (!ink && widget is ElevatedButton) {
        callback = widget.onPressed;
      }
      return callback == null;
    });
    if (callback == null) {
      throw StateError('Release UI control disabled');
    }
    callback!();
  }

  try {
    if (pushNotificationsSupported) {
      throw StateError('Release review requires push isolation');
    }
    final fixture =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (fixture['environment'] != 'isolated-local-performance') {
      throw StateError('Invalid fixture environment');
    }
    await file.delete();
    await waitFor(
      () =>
          locate((e) => e is StatefulElement && e.state is NavigatorState) !=
          null,
    );
    final navigator =
        (locate((e) => e is StatefulElement && e.state is NavigatorState)!
                    as StatefulElement)
                .state
            as NavigatorState;
    step = 'login_ready_review';
    await waitFor(() => locate((e) => e.widget is LoginView) != null);
    final context = navigator.context;
    if (!context.mounted) {
      throw StateError('Release navigator was disposed');
    }
    final auth = context.read<AuthCubit>();
    final location = context.read<LocationCubit>();
    final cart = context.read<CartCubit>();
    final checkout = context.read<CheckoutCubit>();
    step = 'login';
    await auth.login(
      email: fixture['email'] as String,
      password: fixture['password'] as String,
    );
    if (auth.state is! AuthAuthenticated) {
      throw StateError('Release authentication failed');
    }
    final cities = await location.loadAvailableCities();
    if (cities.isEmpty) {
      throw StateError('Fixture city missing');
    }
    location.syncCity(cities.first);
    location.consumeGpsSuggestionSlot();
    await waitFor(() => locate((e) => e.widget is NavigationMenuView) != null);
    await cart.loadCartForUser('performance-release-review');
    if (!await cart.clearLocalCart()) {
      throw StateError('Cart preparation failed');
    }
    await cart.addItem(
      CartItemData(
        id: 'perf-release-item',
        productId: '${fixture['product_id']}',
        variantId: '${fixture['variant_id']}',
        marketId: '${fixture['market_id']}',
        image: '',
        brand: 'PERF',
        title: 'PERF release review',
        price: 10,
        quantity: 1,
      ),
      1,
    );
    checkout.reset();
    step = 'cart';
    unawaited(navigator.pushNamed(AppRoutes.cart));
    await waitFor(() => locate((e) => e.widget is CartView) != null);
    press(AppIcons.add, ink: true);
    await waitFor(
      () => cart.state.length == 1 && cart.state.single.quantity == 2,
    );
    step = 'preview';
    press(AppIcons.card_tick);
    await waitFor(
      () =>
          locate((e) => e.widget is CheckoutView) != null &&
          checkout.state.preview != null &&
          !checkout.state.isPreviewLoading,
    );
    if (checkout.state.previewErrorMessage != null) {
      throw StateError('Release preview failed');
    }
    final total = checkout.state.preview!.summary.grandTotal;
    step = 'confirm';
    press(AppIcons.clipboard_tick);
    await waitFor(() => locate((e) => e.widget is PaymentSuccessView) != null);
    final success =
        locate((e) => e.widget is PaymentSuccessView)!.widget
            as PaymentSuccessView;
    if (success.args?.orderId.isNotEmpty != true) {
      throw StateError('Release confirmation missing order');
    }
    emit({
      'event': 'release_review',
      'status': 'passed',
      'push_isolated': !pushNotificationsSupported,
      'preview_total': total,
      'definition':
          'Functional release UI review through rendered control callbacks; not gesture latency',
    });
  } catch (error) {
    emit({
      'event': 'release_review',
      'status': 'failed',
      'step': step,
      'error_type': error.runtimeType.toString(),
    });
  } finally {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
