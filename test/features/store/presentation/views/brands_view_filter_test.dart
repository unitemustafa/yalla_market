import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/features/store/domain/entities/category_data.dart';
import 'package:yalla_market/features/store/presentation/views/brand/brands_view.dart';

void main() {
  test('all categories page keeps every normal category only', () {
    final categories = [
      _category('normal-1', 'normal'),
      _category('featured-1', 'featured'),
      _category('normal-2', 'normal'),
      _category('popular-1', 'popular'),
      _category('normal-3', 'normal'),
    ];

    final visible = normalCategoriesForAllCategories(categories);

    expect(visible.map((category) => category.id), [
      'normal-1',
      'normal-2',
      'normal-3',
    ]);
  });
}

CategoryData _category(String id, String type) {
  return CategoryData(
    id: id,
    name: id,
    slug: id,
    productCount: 0,
    image: '',
    galleryImages: const [],
    accentColorValue: 0xFF4F60F6,
    classificationType: type,
  );
}
