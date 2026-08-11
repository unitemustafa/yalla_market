import 'package:flutter/widgets.dart';

import '../../../../core/formatters/app_currency.dart';
import '../../../../core/localization/app_translations.dart';

String formatCartMoney(double value, {int fractionDigits = 1}) =>
    AppCurrency.format(value, fractionDigits: fractionDigits);

String cartNotSpecifiedLabel(BuildContext context) =>
    context.isArabicLanguage ? 'غير محدد' : 'Not specified';
