import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../widgets/snackbars/custom_snackbar.dart';

Future<void> copyContentLink({
  required BuildContext context,
  required String link,
  required String successTitle,
}) async {
  try {
    await Clipboard.setData(ClipboardData(text: link));
  } catch (_) {
    if (!context.mounted) return;
    CustomSnackBar.showError(
      context: context,
      title: 'Could not copy link',
      message: 'Please try again.',
    );
    return;
  }
  if (!context.mounted) return;
  CustomSnackBar.showSuccess(
    context: context,
    title: successTitle,
    message: 'You can share it with anyone.',
  );
}
