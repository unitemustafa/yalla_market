import 'package:yalla_market/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/session/account_restored_notifier.dart';

class AccountDisabledView extends StatelessWidget {
  const AccountDisabledView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ValueListenableBuilder<bool>(
                valueListenable: AccountRestoredNotifier.instance,
                builder: (context, isRestored, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRestored
                            ? Icons.lock_open_rounded
                            : Icons.lock_person_rounded,
                        size: 72,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isRestored
                            ? accountRestoredViewMessage
                            : 'تم تعطيل حسابك. تواصل مع الدعم.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: AppFontSizes.subtitle,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (route) => false,
                        ),
                        child: const Text('تسجيل الدخول'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const accountRestoredViewMessage =
    'تم استعادة حسابك. يمكنك الآن الانتقال إلى تسجيل الدخول.';
