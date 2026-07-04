import 'package:flutter/widgets.dart';

import '../../../../../core/localization/app_translations.dart';
import '../../../domain/entities/address.dart';

String localizedAddressText(BuildContext context, AddressData address) {
  final parts = [
    address.street,
    context.tr(address.areaLabel),
    context.tr(address.cityLabel),
  ].where((part) => part.trim().isNotEmpty).toList(growable: false);

  return parts.join(', ');
}
