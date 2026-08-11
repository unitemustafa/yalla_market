import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/cart/presentation/cubit/cart_cubit.dart';
import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/home/presentation/cubit/notification_cubit.dart';
import '../features/location/presentation/cubit/location_cubit.dart';
import '../features/offers/presentation/cubit/offer_catalog_cubit.dart';
import '../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../features/personalization/presentation/cubit/address_cubit.dart';
import '../features/personalization/presentation/cubit/profile_image_cubit.dart';
import '../features/splash/presentation/cubit/splash_cubit.dart';
import '../features/store/presentation/cubit/checkout_cubit.dart';
import '../features/store/presentation/cubit/order_history_cubit.dart';
import '../features/store/presentation/cubit/product_catalog_cubit.dart';
import '../features/store/presentation/cubit/product_discovery_cubit.dart';
import '../features/store/presentation/cubit/store_cubit.dart';
import '../features/wishlist/presentation/cubit/market_wishlist_cubit.dart';
import '../features/wishlist/presentation/cubit/wishlist_cubit.dart';
import 'di/service_locator.dart';

class AppProviders extends StatelessWidget {
  const AppProviders({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthCubit>()),
        BlocProvider(create: (_) => sl<OnboardingCubit>()),
        BlocProvider(create: (_) => sl<LocationCubit>()),
        BlocProvider(create: (_) => sl<SplashCubit>()),
        BlocProvider(create: (_) => sl<HomeCubit>()),
        BlocProvider(create: (_) => sl<OfferCatalogCubit>()),
        BlocProvider(create: (_) => sl<NotificationCubit>()),
        BlocProvider(create: (_) => sl<ProductCatalogCubit>()),
        BlocProvider(create: (_) => sl<ProductDiscoveryCubit>()),
        BlocProvider(create: (_) => sl<StoreCubit>()),
        BlocProvider(create: (_) => sl<CheckoutCubit>()),
        BlocProvider(create: (_) => sl<OrderHistoryCubit>()),
        BlocProvider(create: (_) => sl<CartCubit>()),
        BlocProvider(create: (_) => sl<WishlistCubit>()),
        BlocProvider(create: (_) => sl<MarketWishlistCubit>()),
        BlocProvider(create: (_) => sl<AddressCubit>()),
        BlocProvider(create: (_) => sl<ProfileImageCubit>()),
      ],
      child: child,
    );
  }
}
