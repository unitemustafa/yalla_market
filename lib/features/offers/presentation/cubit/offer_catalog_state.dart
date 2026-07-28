import '../../domain/entities/offer_data.dart';

class OfferCatalogState {
  const OfferCatalogState({
    this.offers = const [],
    this.isLoading = false,
    this.hasLoaded = false,
    this.errorMessage,
  });

  final List<OfferData> offers;
  final bool isLoading;
  final bool hasLoaded;
  final String? errorMessage;

  OfferCatalogState copyWith({
    List<OfferData>? offers,
    bool? isLoading,
    bool? hasLoaded,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OfferCatalogState(
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
