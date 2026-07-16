import '../../../../core/network/api_result.dart';
import '../../../store/data/repositories/product_repository_impl.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl() : _productsRepository = ProductRepositoryImpl();

  final ProductRepositoryImpl _productsRepository;

  @override
  Future<ApiResult<HomeData>> getHome({bool forceRefresh = false}) async {
    final productsResult = await _productsRepository.getProducts();
    final categoriesResult = await _productsRepository.getCategories();

    return productsResult.when(
      success: (products) {
        return categoriesResult.when(
          success: (categories) => ApiResult.success(
            HomeData(
              location: null,
              offers: products.isEmpty
                  ? const []
                  : [
                      HomeOfferData(
                        id: 'local-demo-offer',
                        title: 'Weekly Package',
                        description: 'Demo offer for local development.',
                        image: products.first.image,
                        type: 'package',
                        discount: '10',
                        startsAt: null,
                        endsAt: DateTime.now().add(const Duration(days: 7)),
                        marketName: products.first.brand,
                        products: products.take(3).toList(growable: false),
                      ),
                    ],
              categories: categories,
              products: products,
            ),
          ),
          failure: ApiResult.failure,
        );
      },
      failure: ApiResult.failure,
    );
  }
}
