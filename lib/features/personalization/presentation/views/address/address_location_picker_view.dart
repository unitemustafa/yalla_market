import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/maptiler_map_config.dart';
import '../../../../../core/config/app_map_tile_provider.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/search/app_search_actions_bar.dart';
import '../../../../location/domain/entities/city_data.dart';
import '../../../../location/domain/services/device_location_service.dart';
import '../../../../location/domain/utils/geo_coverage.dart';
import '../../../domain/entities/geocoding_place.dart';
import '../../../domain/repositories/map_geocoding_repository.dart';
import '../../controllers/address_location_picker_controller.dart';
import '../../widgets/address_location_map_widgets.dart';
import '../../widgets/address_location_search_widgets.dart';

export '../../controllers/address_location_picker_controller.dart';

class AddressLocationPickerView extends StatefulWidget {
  const AddressLocationPickerView({
    super.key,
    required this.locationDataSource,
    required this.geocodingDataSource,
    required this.fallbackCoordinates,
    this.selectedCity,
    this.initialLocation,
    this.tileUrlTemplateOverride,
  });

  final DeviceLocationService locationDataSource;
  final MapGeocodingRepository geocodingDataSource;
  final DeviceCoordinates fallbackCoordinates;
  final CityData? selectedCity;
  final SelectedMapLocation? initialLocation;
  final String? tileUrlTemplateOverride;

  @override
  State<AddressLocationPickerView> createState() =>
      _AddressLocationPickerViewState();
}

class _AddressLocationPickerViewState extends State<AddressLocationPickerView>
    with WidgetsBindingObserver {
  late final AddressLocationPickerController _selectionController;
  late final NetworkTileProvider _tileProvider;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _searchDebounce;
  Timer? _reverseDebounce;
  int _searchGeneration = 0;
  int _reverseGeneration = 0;
  List<GeocodingPlace> _searchResults = const [];
  bool _isSearching = false;
  bool _searchFailed = false;
  bool _mapReady = false;
  bool _searchMode = false;
  bool _hasUserInteracted = false;
  DeviceCoordinates? _lastRenderedTarget;

  String get _language =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tileProvider = createAppMapTileProvider();
    _selectionController = AddressLocationPickerController(
      locationDataSource: widget.locationDataSource,
      fallbackCoordinates: widget.fallbackCoordinates,
      initialLocation: widget.initialLocation,
      isWithinCoverage: _isWithinSelectedCity,
    )..addListener(_onSelectionChanged);
    unawaited(_initializeLocation());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _reverseDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    _selectionController
      ..removeListener(_onSelectionChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_selectionController.canConfirm &&
        !_selectionController.isLoading) {
      unawaited(_initializeLocation());
    }
  }

  Future<void> _initializeLocation() async {
    final coordinates = await _selectionController.initialize();
    if (!mounted || coordinates == null) return;
    _moveMap(coordinates, zoom: 16);
    _scheduleReverse(coordinates);
  }

  void _onSelectionChanged() {
    if (!mounted) return;
    final target = _selectionController.target;
    if (_mapReady &&
        !_hasUserInteracted &&
        _selectionController.usesCurrentLocation &&
        !_sameCoordinates(_lastRenderedTarget, target)) {
      _moveMap(target, zoom: 16);
      _scheduleReverse(target);
    }
    setState(() {});
  }

  Future<void> _moveToCurrentLocation() async {
    final coordinates = await _selectionController.useCurrentLocation();
    if (!mounted || coordinates == null) return;
    _moveMap(coordinates, zoom: 16);
    _scheduleReverse(coordinates);
  }

  void _moveMap(DeviceCoordinates coordinates, {double? zoom}) {
    if (!_mapReady) return;
    _lastRenderedTarget = coordinates;
    _mapController.move(
      LatLng(coordinates.latitude, coordinates.longitude),
      zoom ?? _mapController.camera.zoom,
    );
  }

  void _onMapEvent(MapEvent event) {
    if (!_selectionController.canConfirm ||
        event.source == MapEventSource.mapController) {
      return;
    }
    if (event is MapEventMoveStart ||
        event is MapEventMove ||
        event is MapEventFlingAnimationStart) {
      _hasUserInteracted = true;
    }
    if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
      final center = event.camera.center;
      final coordinates = DeviceCoordinates(center.latitude, center.longitude);
      _lastRenderedTarget = coordinates;
      _selectionController.selectManual(coordinates);
      _scheduleReverse(coordinates);
    }
  }

  bool _isWithinSelectedCity(DeviceCoordinates coordinates) {
    final city = widget.selectedCity;
    if (city == null) return true;

    final knownCity = CityData.fromName(city.name);
    if (city.isGeneral && !city.isNamedGeneral && knownCity == null) {
      return true;
    }
    if (knownCity?.slug == 'cairo') {
      final isInsideSafeCityCap = geoCoverageContains(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        centerLatitude: 30.0444,
        centerLongitude: 31.2357,
        radiusKm: 50,
      );
      if (!isInsideSafeCityCap) return false;
    }
    if (knownCity?.slug == 'sharm-el-sheikh') {
      final isInsideSafeCityCap = geoCoverageContains(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        centerLatitude: 27.9158,
        centerLongitude: 34.3299,
        radiusKm: 40,
      );
      if (!isInsideSafeCityCap) return false;
    }

    if (city.boundaryGeoJson != null || city.boundaryBbox != null) {
      return geoCoverageContains(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        boundaryGeoJson: city.boundaryGeoJson,
        boundaryBbox: city.boundaryBbox,
        centerLatitude: city.centerLatitude,
        centerLongitude: city.centerLongitude,
        radiusKm: city.radiusKm,
      );
    }

    if (knownCity == null &&
        (city.centerLatitude == null ||
            city.centerLongitude == null ||
            city.radiusKm == null)) {
      return false;
    }
    return geoCoverageContains(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      centerLatitude: knownCity?.slug == 'cairo'
          ? 30.0444
          : knownCity?.slug == 'sharm-el-sheikh'
          ? 27.9158
          : city.centerLatitude,
      centerLongitude: knownCity?.slug == 'cairo'
          ? 31.2357
          : knownCity?.slug == 'sharm-el-sheikh'
          ? 34.3299
          : city.centerLongitude,
      radiusKm: knownCity?.slug == 'cairo'
          ? 50
          : knownCity?.slug == 'sharm-el-sheikh'
          ? 40
          : city.radiusKm,
    );
  }

  bool _sameCoordinates(DeviceCoordinates? first, DeviceCoordinates second) {
    if (first == null) return false;
    return (first.latitude - second.latitude).abs() < 0.0000001 &&
        (first.longitude - second.longitude).abs() < 0.0000001;
  }

  void _scheduleReverse(DeviceCoordinates coordinates) {
    _reverseDebounce?.cancel();
    final generation = ++_reverseGeneration;
    _reverseDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(_reverseGeocode(coordinates, generation));
    });
  }

  Future<void> _reverseGeocode(
    DeviceCoordinates coordinates,
    int generation,
  ) async {
    try {
      final place = await widget.geocodingDataSource.reverse(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        language: _language,
      );
      if (!mounted || generation != _reverseGeneration) return;
      _selectionController.applyReverseResult(coordinates, place);
    } catch (_) {
      if (!mounted || generation != _reverseGeneration) return;
    }
  }

  void _onSearchChanged(String rawQuery) {
    _searchDebounce?.cancel();
    final query = rawQuery.trim();
    final generation = ++_searchGeneration;
    if (query.length < 3) {
      setState(() {
        _isSearching = false;
        _searchFailed = false;
        _searchResults = const [];
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _searchFailed = false;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_search(query, generation));
    });
  }

  Future<void> _search(String query, int generation) async {
    final center = _selectionController.target;
    try {
      final results = await widget.geocodingDataSource.autocomplete(
        query: query,
        latitude: center.latitude,
        longitude: center.longitude,
        language: _language,
      );
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searchResults = results.take(5).toList(growable: false);
        _isSearching = false;
        _searchFailed = false;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
        _searchFailed = true;
      });
    }
  }

  void _selectSearchResult(GeocodingPlace place) {
    _searchDebounce?.cancel();
    _reverseDebounce?.cancel();
    _reverseGeneration++;
    _selectionController.selectSearchResult(place);
    _hasUserInteracted = true;
    _moveMap(placeCoordinates(place), zoom: 17);
    _searchController.text = place.displayAddress;
    _searchController.selection = TextSelection.collapsed(
      offset: _searchController.text.length,
    );
    _searchFocus.unfocus();
    setState(() {
      _searchMode = false;
      _searchResults = const [];
      _searchFailed = false;
    });
  }

  void _openSearch() {
    setState(() => _searchMode = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchDebounce?.cancel();
    _searchGeneration++;
    _searchFocus.unfocus();
    _searchController.clear();
    setState(() {
      _searchMode = false;
      _isSearching = false;
      _searchFailed = false;
      _searchResults = const [];
    });
  }

  DeviceCoordinates placeCoordinates(GeocodingPlace place) =>
      DeviceCoordinates(place.latitude, place.longitude);

  void _retrySearch() {
    final query = _searchController.text.trim();
    if (query.length < 3) return;
    final generation = ++_searchGeneration;
    setState(() {
      _isSearching = true;
      _searchFailed = false;
    });
    unawaited(_search(query, generation));
  }

  void _confirm() {
    if (!_selectionController.canConfirm ||
        !_isWithinSelectedCity(_selectionController.target)) {
      return;
    }
    Navigator.pop(context, _selectionController.selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body:
          !MapTilerMapConfig.isConfigured &&
              widget.tileUrlTemplateOverride == null
          ? const MissingMapConfiguration()
          : SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(child: _buildMapPage()),
                  if (_searchMode)
                    Positioned.fill(
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, value, child) =>
                            Opacity(opacity: value, child: child),
                        child: _buildSearchPage(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMapPage() {
    final target = _selectionController.target;
    final isInsideCity = _isWithinSelectedCity(target);
    final formattedAddress = _selectionController.formattedAddress?.trim();
    final locationLabel = formattedAddress?.isNotEmpty == true
        ? formattedAddress!
        : widget.selectedCity?.displayName(
            arabic: Localizations.localeOf(context).languageCode != 'en',
          );

    return AddressLocationMapPage(
      mapController: _mapController,
      tileProvider: _tileProvider,
      target: target,
      tileUrlTemplate:
          widget.tileUrlTemplateOverride ?? MapTilerMapConfig.tileUrl(),
      isInsideCity: isInsideCity,
      locationLabel: locationLabel,
      title: context.tr('Delivery address'),
      deliveryMessage: context.tr(
        isInsideCity
            ? 'Your order will be delivered to this location'
            : 'Outside the delivery area. Adjust the location.',
      ),
      currentLocationTooltip: context.tr('Current location'),
      isLocating: _selectionController.isLoading,
      onClose: () => Navigator.maybePop(context),
      onSearch: _openSearch,
      onMapReady: () {
        _mapReady = true;
        _moveMap(_selectionController.target, zoom: 16);
      },
      onMapEvent: _onMapEvent,
      onConfirm: isInsideCity ? _confirm : null,
      onCurrentLocation: _moveToCurrentLocation,
      onOpenUrl: _openUrl,
    );
  }

  Widget _buildSearchPage() {
    return ColoredBox(
      key: const ValueKey('map-picker-search-page'),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                CompactMapButton(
                  key: const ValueKey('map-picker-search-close'),
                  onPressed: _closeSearch,
                  icon: Icons.close_rounded,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  elevation: 0,
                  borderColor: Theme.of(context).dividerColor,
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildSearchField()),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(child: _buildSearchContent()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return AppSearchField(
      key: const ValueKey('map-picker-search-field'),
      controller: _searchController,
      focusNode: _searchFocus,
      onChanged: _onSearchChanged,
      hintText: 'Search for a place in Egypt',
    );
  }

  Widget _buildSearchContent() {
    return AddressLocationSearchContent(
      isSearching: _isSearching,
      searchFailed: _searchFailed,
      results: _searchResults,
      failureMessage: context.tr('Place search failed.'),
      retryLabel: context.tr('Retry'),
      onRetry: _retrySearch,
      onSelected: _selectSearchResult,
    );
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
