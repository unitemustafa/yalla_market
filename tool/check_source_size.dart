import 'dart:io';

const _maximumLines = 500;

// Existing refactoring debt. Remove a path as soon as it drops below the
// limit; new files are never allowed to join this list.
const _existingDebt = <String>{
  'lib/core/localization/app_translation_phrases.dart',
  'lib/core/presentation/widgets/products/product_cards/product_card_vertical.dart',
  'lib/features/auth/data/repositories/auth_remote_repository_impl.dart',
  'lib/features/auth/data/repositories/auth_repository_impl.dart',
  'lib/features/auth/presentation/cubit/auth_cubit.dart',
  'lib/features/auth/presentation/views/forget_password_view.dart',
  'lib/features/auth/presentation/views/login_view.dart',
  'lib/features/auth/presentation/views/signup_availability_checker.dart',
  'lib/features/auth/presentation/views/verify_email_view.dart',
  'lib/features/home/presentation/views/home_view.dart',
  'lib/features/location/domain/entities/city_data.dart',
  'lib/features/location/presentation/views/select_city_view.dart',
  'lib/features/location/presentation/widgets/city_selection_panel.dart',
  'lib/features/navigation/presentation/views/navigation_menu_view.dart',
  'lib/features/offers/presentation/widgets/promo_slider.dart',
  'lib/features/offers/presentation/widgets/promo_slider_sheet_part.dart',
  'lib/features/personalization/presentation/views/profile/edit_profile_birth_date_picker.dart',
  'lib/features/personalization/presentation/views/profile/profile_view.dart',
  'lib/features/search/presentation/views/search_view.dart',
  'lib/features/store/domain/entities/order.dart',
  'lib/features/store/domain/entities/product_data.dart',
  'lib/features/store/presentation/views/brand/brand_products_view.dart',
  'lib/features/store/presentation/views/checkout/payment_success_view.dart',
  'lib/features/store/presentation/views/checkout_action_and_shared.dart',
  'lib/features/store/presentation/views/checkout_view.dart',
  'lib/features/store/presentation/views/product_detail_dialogs_part.dart',
  'lib/yalla_market_app.dart',
};

void main() {
  final oversized = <String, int>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll('\\', '/');
    final lines = entity.readAsLinesSync().length;
    if (lines > _maximumLines && !_existingDebt.contains(path)) {
      oversized[path] = lines;
    }
  }

  if (oversized.isNotEmpty) {
    stderr.writeln('New Dart files exceed $_maximumLines lines:');
    for (final entry in oversized.entries) {
      stderr.writeln('- ${entry.key}: ${entry.value}');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Source-size ratchet passed; ${_existingDebt.length} legacy files remain.',
  );
}
