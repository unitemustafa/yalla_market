import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('architecture dependency ratchet', () {
    test('Cubits do not acquire new repository, data, or storage imports', () {
      const existingDebt = <String>{};

      final violations = _importsUnder('lib/features')
          .where((entry) => entry.path.endsWith('_cubit.dart'))
          .where(
            (entry) =>
                entry.import.contains('/domain/repositories/') ||
                entry.import.contains('/data/') ||
                entry.import.contains('package:shared_preferences/'),
          )
          .map((entry) => entry.path)
          .toSet();

      expect(violations, existingDebt);
    });

    test('presentation does not acquire new data-layer imports', () {
      const existingDebt = <String>{};

      final violations = _importsUnder('lib/features')
          .where((entry) => entry.path.contains('/presentation/'))
          .where((entry) => entry.import.contains('/data/'))
          .map((entry) => entry.path)
          .toSet();

      expect(violations, existingDebt);
    });

    test('domain does not acquire new API or asset dependencies', () {
      const existingDebt = {
        'lib/features/home/domain/entities/home_data.dart',
        'lib/features/offers/domain/entities/offer_data.dart',
        'lib/features/store/domain/entities/product_data.dart',
        'lib/features/store/domain/entities/store_data.dart',
      };

      final violations = _importsUnder('lib/features')
          .where((entry) => entry.path.contains('/domain/'))
          .where(
            (entry) =>
                entry.import.contains('core/network/api_endpoints.dart') ||
                entry.import.contains('core/constants/app_assets.dart'),
          )
          .map((entry) => entry.path)
          .toSet();

      expect(violations, existingDebt);
    });

    test('domain remains independent of Flutter and feature UI/data', () {
      final violations = _importsUnder('lib/features')
          .where((entry) => entry.path.contains('/domain/'))
          .where(
            (entry) =>
                entry.import.startsWith('package:flutter/') ||
                entry.import.startsWith('package:flutter_bloc/') ||
                entry.import.contains('/presentation/') ||
                entry.import.contains('/data/'),
          )
          .toList(growable: false);

      expect(violations, isEmpty);
    });

    test('feature-coupled core widgets do not expand', () {
      const existingDebt = {
        'lib/core/presentation/widgets/products/cart_counter_icon.dart',
        'lib/core/presentation/widgets/products/product_results_view.dart',
        'lib/core/presentation/widgets/products/product_cards/product_card_vertical.dart',
      };

      final violations = _importsUnder('lib/core/presentation')
          .where((entry) => entry.import.contains('/features/'))
          .map((entry) => entry.path)
          .toSet();

      expect(violations, existingDebt);
    });

    test('core has no new direct feature dependencies', () {
      const existingDebt = {
        'lib/core/presentation/widgets/products/cart_counter_icon.dart',
        'lib/core/presentation/widgets/products/product_results_view.dart',
        'lib/core/presentation/widgets/products/product_cards/product_card_vertical.dart',
      };

      final violations = _importsUnder('lib/core')
          .where((entry) => entry.import.contains('/features/'))
          .map((entry) => entry.path)
          .toSet();

      expect(violations, existingDebt);
    });

    test(
      'application composition does not return to core compatibility paths',
      () {
        final violations = _importsUnder('lib')
            .where(
              (entry) =>
                  entry.import.contains('core/routing/') ||
                  entry.import.endsWith('core/di/service_locator.dart'),
            )
            .toList(growable: false);

        expect(violations, isEmpty);
        expect(Directory('lib/core/routing').existsSync(), isFalse);
        expect(File('lib/core/di/service_locator.dart').existsSync(), isFalse);
      },
    );
  });
}

Iterable<_ImportEntry> _importsUnder(String rootPath) sync* {
  final root = Directory(rootPath);
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll('\\', '/');
    for (final line in entity.readAsLinesSync()) {
      final match = RegExp("^import ['\"]([^'\"]+)['\"];").firstMatch(line);
      if (match == null) continue;
      yield _ImportEntry(path, match.group(1)!);
    }
  }
}

class _ImportEntry {
  const _ImportEntry(this.path, this.import);

  final String path;
  final String import;
}
