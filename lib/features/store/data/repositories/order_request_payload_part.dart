part of 'order_remote_repository_impl.dart';

({Map<String, Object?>? payload, ValidationFailure? failure}) _productPayload({
  required String? variantId,
  required int quantity,
  List<String> additionIds = const [],
}) {
  final parsedVariantId = _positiveIdFromValue(variantId);
  if (parsedVariantId == null) {
    return (
      payload: null,
      failure: const ValidationFailure(
        'Some cart items are missing variant information. Please add them again.',
      ),
    );
  }
  if (quantity <= 0) {
    return (
      payload: null,
      failure: const ValidationFailure(
        'Cart items must have a quantity greater than zero.',
      ),
    );
  }
  final additions = additionIds.map((value) {
    final id = int.tryParse(value.trim());
    return id != null && id > 0 ? id : null;
  }).toList();
  if (additions.any((id) => id == null) ||
      additions.toSet().length != additions.length) {
    return (
      payload: null,
      failure: const ValidationFailure(
        'Some selected additions are invalid. Please add the product again.',
      ),
    );
  }
  final sortedAdditions = additions.cast<int>()..sort();
  return (
    payload: {
      'variant_id': parsedVariantId,
      'quantity': quantity,
      if (sortedAdditions.isNotEmpty) 'addition_ids': sortedAdditions,
    },
    failure: null,
  );
}

String? _normalizePaymentMethod(String? paymentMethod) {
  final value = paymentMethod?.trim().toLowerCase();
  if (value == null || value.isEmpty) return 'cash';
  if (value == 'cash' || value == 'cash_on_delivery') return 'cash';
  return null;
}

Failure _checkoutError(DioException error) {
  final statusCode = error.response?.statusCode;
  final data = error.response?.data;
  if (data is Map) {
    if (_truthy(data['requires_region_selection'])) {
      return ValidationFailure(
        checkoutRegionRequiredMessage,
        statusCode: statusCode,
      );
    }
    if (_truthy(data['requires_address_selection']) ||
        data.containsKey('address_id') ||
        data.containsKey('delivery_address_id')) {
      return ValidationFailure(
        checkoutAddressRequiredMessage,
        statusCode: statusCode,
      );
    }
    if (data.containsKey('payment_method')) {
      return ValidationFailure(
        checkoutPaymentRequiredMessage,
        statusCode: statusCode,
      );
    }
    if (data.containsKey('shipping_company_id')) {
      return const ValidationFailure(checkoutShippingCompanyRequiredMessage);
    }
    if (data.containsKey('items')) {
      return ValidationFailure(
        _arabicMessageFrom(data['items']) ?? checkoutItemsInvalidMessage,
        statusCode: statusCode,
      );
    }
    if (data.containsKey('offers')) {
      return ValidationFailure(
        _arabicMessageFrom(data['offers']) ?? checkoutOffersInvalidMessage,
        statusCode: statusCode,
      );
    }
    if (data.containsKey('non_field_errors')) {
      return ValidationFailure(
        _arabicMessageFrom(data['non_field_errors']) ??
            checkoutOrderInvalidMessage,
        statusCode: statusCode,
      );
    }
    if (_mentionsRegionSelection(data['message'])) {
      return ValidationFailure(
        checkoutRegionRequiredMessage,
        statusCode: statusCode,
      );
    }
  }

  final fallback = ApiErrorHandler.handle(error);
  if (_isSuppressedCheckoutMessage(fallback.message)) {
    return ValidationFailure(
      checkoutOrderInvalidMessage,
      statusCode: statusCode,
    );
  }
  return fallback;
}

bool _truthy(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  if (value is Iterable) return value.any(_truthy);
  return false;
}

bool _mentionsRegionSelection(Object? value) {
  final messages = <String>[];
  _collectMessages(value, messages);
  return messages.any(
    (message) => message.toLowerCase().contains('market browsing region'),
  );
}

String? _arabicMessageFrom(Object? value) {
  final messages = <String>[];
  _collectMessages(value, messages);
  for (final message in messages) {
    if (_isSuppressedCheckoutMessage(message)) continue;
    if (_containsArabic(message)) return message;
  }
  return null;
}

void _collectMessages(Object? value, List<String> messages) {
  if (value is String && value.trim().isNotEmpty) {
    messages.add(value.trim());
    return;
  }
  if (value is Map) {
    for (final entry in value.entries) {
      if (entry.key == 'current_selection') continue;
      _collectMessages(entry.value, messages);
    }
    return;
  }
  if (value is Iterable) {
    for (final item in value) {
      _collectMessages(item, messages);
    }
  }
}

bool _containsArabic(String value) =>
    RegExp(r'[\u0600-\u06FF]').hasMatch(value);

bool _isSuppressedCheckoutMessage(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty ||
      normalized == 'true' ||
      normalized == 'none' ||
      normalized == 'this field is required.' ||
      normalized == 'current_selection';
}

int? _offerIdFromCartItem(CartItemData item) {
  return _offerIdFromValue(item.productId) ?? _offerIdFromValue(item.id);
}

Object? _idFromString(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return int.tryParse(trimmed) ?? trimmed;
}

int? _positiveIdFromValue(Object? value) {
  final id = _offerIdFromValue(value);
  return id != null && id > 0 ? id : null;
}

int? _offerIdFromValue(Object? value) {
  if (value is int) return value > 0 ? value : null;
  if (value is num) {
    final id = value.toInt();
    return value == id && id > 0 ? id : null;
  }

  final trimmed = value?.toString().trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final directId = int.tryParse(trimmed);
  if (directId != null) return directId > 0 ? directId : null;

  final clearOfferId = RegExp(
    r'^offer[_-](\d+)$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (clearOfferId == null) return null;

  final parsedId = int.tryParse(clearOfferId.group(1)!);
  return parsedId != null && parsedId > 0 ? parsedId : null;
}
