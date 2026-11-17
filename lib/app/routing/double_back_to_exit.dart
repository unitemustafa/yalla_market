import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/localization/app_translations.dart';

/// Confirms Android app exit while preserving navigation between pages.
class DoubleBackToExit extends StatefulWidget {
  const DoubleBackToExit({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit>
    with WidgetsBindingObserver {
  static const _confirmationWindow = Duration(seconds: 2);
  Timer? _confirmationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.isCurrentOf(context) != true) {
      _confirmationTimer?.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant DoubleBackToExit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _confirmationTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _confirmationTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _confirmationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shouldConfirmExit =
        widget.enabled &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        ModalRoute.isFirstOf(context) == true;

    return PopScope<Object?>(
      canPop: !shouldConfirmExit,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop ||
            !shouldConfirmExit ||
            ModalRoute.isCurrentOf(context) != true) {
          return;
        }
        final messenger = ScaffoldMessenger.of(context);
        if (_confirmationTimer?.isActive ?? false) {
          _confirmationTimer?.cancel();
          messenger.hideCurrentSnackBar();
          unawaited(SystemNavigator.pop());
          return;
        }
        _confirmationTimer = Timer(_confirmationWindow, () {});
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.tr('Press back again to exit')),
              duration: _confirmationWindow,
            ),
          );
      },
      child: widget.child,
    );
  }
}
