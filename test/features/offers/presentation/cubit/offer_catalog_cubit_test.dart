import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_market/core/network/api_result.dart';
import 'package:yalla_market/features/offers/domain/entities/offer_data.dart';
import 'package:yalla_market/features/offers/domain/repositories/offer_repository.dart';
import 'package:yalla_market/features/offers/domain/usecases/get_offers_usecase.dart';
import 'package:yalla_market/features/offers/presentation/cubit/offer_catalog_cubit.dart';

void main() {
  test('cached offers do not make the catalog fresh', () async {
    final repository = _OfferRepository(
      origins: [DataOrigin.cache, DataOrigin.network],
    );
    final cubit = OfferCatalogCubit(GetOffersUseCase(repository));
    addTearDown(cubit.close);

    await cubit.loadOffers();
    await cubit.loadOffers();

    expect(repository.calls, 2);
  });

  test('network offers remain fresh for 60 seconds', () async {
    var now = DateTime.utc(2030, 1, 1, 12);
    final repository = _OfferRepository();
    final cubit = OfferCatalogCubit(
      GetOffersUseCase(repository),
      now: () => now,
    );
    addTearDown(cubit.close);

    await cubit.loadOffers();
    now = now.add(const Duration(seconds: 59));
    await cubit.loadOffers();
    expect(repository.calls, 1);

    now = now.add(const Duration(seconds: 1));
    await cubit.loadOffers();
    expect(repository.calls, 2);
  });
}

class _OfferRepository implements OfferRepository {
  _OfferRepository({this.origins = const [DataOrigin.network]});

  final List<DataOrigin> origins;
  int calls = 0;

  @override
  Future<ApiResult<List<OfferData>>> getOffers() async {
    final origin = origins[calls < origins.length ? calls : origins.length - 1];
    calls++;
    return ApiResult.success(const [_offer], origin: origin);
  }
}

const _offer = OfferData(
  id: 'offer',
  title: 'Offer',
  description: '',
  image: '',
  type: 'product',
  discount: '10',
  startsAt: null,
  endsAt: null,
  marketName: 'Market',
  products: [],
);
