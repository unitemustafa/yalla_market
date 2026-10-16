import 'package:yalla_market/core/constants/app_assets.dart';
import 'package:yalla_market/features/home/domain/entities/app_notification.dart';
import 'package:yalla_market/features/store/domain/entities/category_data.dart';
import 'package:yalla_market/features/store/domain/entities/order.dart';
import 'package:yalla_market/features/store/domain/entities/product_data.dart';
import 'package:yalla_market/features/store/domain/entities/store_data.dart';
import 'package:yalla_market/features/wishlist/domain/entities/wishlist_item.dart';

/// Test-only data. Never installed in production repositories.
class StressFixtures {
  StressFixtures({
    this.productCount = 10000,
    this.listCount = 1000,
    this.imageNamespace = '',
  }) {
    products = List.unmodifiable(
      List.generate(
        productCount,
        (index) => ProductData(
          id: '${index + 1}',
          slug: 'stress-product-${index + 1}',
          title: 'Product ${index.toString().padLeft(5, '0')}',
          brand: 'Stress store',
          price: '${10 + index % 90}',
          oldPrice: null,
          discount: '',
          image: image(index),
          images: [image(index)],
          tags: const ['stress'],
          marketId: '1',
          subcategoryId: index.isEven ? 'even' : 'odd',
          isPopular: index < 5,
          variants: [
            ProductVariantData(id: '${index + 1}', price: '${10 + index % 90}'),
          ],
          description: 'Deterministic performance fixture.',
        ),
      ),
    );
    markets = List.unmodifiable(
      List.generate(
        listCount,
        (index) => StoreMarketData(
          id: '${index + 1}',
          name: 'Store $index',
          branch: 'Fixture',
          status: 'active',
          classificationId: 'stress',
          products: index == 0 ? products : const [],
          subcategories: const [
            StoreSubcategoryData(id: 'even', nameAr: 'زوجي', nameEn: 'Even'),
            StoreSubcategoryData(id: 'odd', nameAr: 'فردي', nameEn: 'Odd'),
          ],
          image: image(index),
          coverImage: image(index),
          accentColorValue: 0xFF013C7E,
        ),
      ),
    );
    categories = List.unmodifiable(
      List.generate(
        listCount,
        (index) => CategoryData(
          id: 'category-$index',
          name: 'Category $index',
          slug: 'category-$index',
          productCount: 1,
          marketCount: 1,
          image: image(index),
          galleryImages: const [],
          accentColorValue: 0xFF013C7E,
        ),
      ),
    );
    wishlist = List.unmodifiable(
      products
          .take(listCount)
          .map(
            (product) => WishlistItem(
              productId: product.id,
              title: product.title,
              brand: product.brand,
              price: product.price,
              image: product.image,
            ),
          ),
    );
    notifications = List.unmodifiable(
      List.generate(
        listCount,
        (index) => AppNotification(
          id: index + 1,
          audience: 'client',
          type: 'announcement',
          title: 'Notification $index',
          message: 'Performance fixture $index',
          createdAt: DateTime.utc(
            2026,
            10,
            12,
          ).subtract(Duration(minutes: index)),
        ),
      ),
    );
    orders = List.unmodifiable(
      List.generate(
        listCount,
        (index) => OrderData.fromJson({
          'id': index + 1,
          'order_number': 'PERF-${index + 1}',
          'status': 'processing',
          'created_at': '2026-10-12T10:00:00Z',
          'items': [
            {
              'id': index + 1,
              'product_id': 1,
              'name': 'Fixture product',
              'quantity': 1,
              'price': '20',
              'image': image(index),
            },
          ],
          'total': '20',
          'subtotal': '20',
          'shipping_fee': '0',
        }),
      ),
    );
  }

  final int productCount;
  final int listCount;

  /// A run-specific URL query keeps cold image runs out of the disk cache.
  final String imageNamespace;
  late final List<ProductData> products;
  late final List<StoreMarketData> markets;
  late final List<CategoryData> categories;
  late final List<WishlistItem> wishlist;
  late final List<AppNotification> notifications;
  late final List<OrderData> orders;

  static const imageBaseUrl = String.fromEnvironment('PERF_IMAGE_BASE_URL');
  String image(int index) {
    if (imageBaseUrl.isEmpty) return AppAssets.defaultProduct;
    // Distinct cache keys per item; content cycles through diverse fixtures.
    final url = '$imageBaseUrl/images/${index + 1}.webp';
    return imageNamespace.isEmpty ? url : '$url?run=$imageNamespace';
  }

  StoreData get store => StoreData(
    commonClassifications: const [],
    classifications: [
      StoreClassificationData(
        id: 'stress',
        name: 'Stress',
        marketCount: listCount,
        products: const [],
        image: image(0),
        accentColorValue: 0xFF013C7E,
        classificationType: 'normal',
      ),
    ],
    marketsByClassificationId: {'stress': markets},
    latestMarkets: markets.take(5).toList(),
  );

  Map<String, Object?> get storefrontPayload => {
    'id': 1,
    'name': 'Stress store',
    'classification_id': 'stress',
    'status': 'active',
    'image': image(0),
    'products': products.map((product) => product.toJson()).toList(),
  };
}
