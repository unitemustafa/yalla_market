import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/maptiler_map_config.dart';
import '../../../../../core/config/app_map_tile_provider.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../location/data/datasources/device_location_data_source.dart';
import '../../../../location/domain/entities/city_data.dart';
import '../../../../location/domain/utils/geo_coverage.dart';
import '../../../data/datasources/geoapify_geocoding_data_source.dart';

class SelectedMapLocation {
  const SelectedMapLocation({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    this.placeId,
  });

  final double latitude;
  final double longitude;
  final String? formattedAddress;
  final String? placeId;

  DeviceCoordinates get coordinates => DeviceCoordinates(latitude, longitude);
}

enum LocationGateStatus {
  checking,
  ready,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  unavailable,
}

class AddressLocationPickerController extends ChangeNotifier {
  AddressLocationPickerController({
    required DeviceLocationDataSource locationDataSource,
    required DeviceCoordinates fallbackCoordinates,
    SelectedMapLocation? initialLocation,
    bool Function(DeviceCoordinates coordinates)? isWithinCoverage,
  }) : _locationDataSource = locationDataSource,
       _initialLocation = initialLocation,
       _isWithinCoverage = isWithinCoverage,
       _target = initialLocation?.coordinates ?? fallbackCoordinates,
       _formattedAddress = initialLocation?.formattedAddress,
       _placeId = initialLocation?.placeId;

  final DeviceLocationDataSource _locationDataSource;
  final SelectedMapLocation? _initialLocation;
  final bool Function(DeviceCoordinates coordinates)? _isWithinCoverage;
  DeviceCoordinates _target;
  LocationGateStatus _gateStatus = LocationGateStatus.ready;
  bool _isLocating = false;
  bool _usesCurrentLocation = false;
  String? _errorMessage;
  String? _formattedAddress;
  String? _placeId;

  DeviceCoordinates get target => _target;
  LocationGateStatus get gateStatus => _gateStatus;
  bool get isLoading => _isLocating;
  bool get canConfirm => true;
  bool get usesCurrentLocation => _usesCurrentLocation;
  String? get errorMessage => _errorMessage;
  String? get formattedAddress => _formattedAddress;
  String? get placeId => _placeId;

  SelectedMapLocation get selectedLocation => SelectedMapLocation(
    latitude: _target.latitude,
    longitude: _target.longitude,
    formattedAddress: _formattedAddress,
    placeId: _placeId,
  );

  Future<DeviceCoordinates?> initialize() async {
    _gateStatus = LocationGateStatus.ready;
    _errorMessage = null;
    notifyListeners();
    if (_initialLocation == null) unawaited(_hydrateCurrentLocation());
    return _target;
  }

  Future<DeviceCoordinates?> useCurrentLocation() async {
    _isLocating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final coordinates = await _locationDataSource.resolveCurrentCoordinates();
      if (!isWithinCoverage(coordinates)) {
        _errorMessage = 'Your current location is outside the delivery area.';
        return null;
      }
      _target = coordinates;
      _gateStatus = LocationGateStatus.ready;
      _usesCurrentLocation = true;
      _errorMessage = null;
      _formattedAddress = null;
      _placeId = null;
      return coordinates;
    } on LocationSelectionException catch (error) {
      _setLocationFailure(error);
      return null;
    } catch (_) {
      _gateStatus = LocationGateStatus.unavailable;
      _usesCurrentLocation = false;
      _errorMessage = 'Could not find your current location. Try again.';
      return null;
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

  Future<void> _hydrateCurrentLocation() async {
    final lastKnown = await _locationDataSource.resolveLastKnownCoordinates();
    if (_initialLocation == null &&
        lastKnown != null &&
        isWithinCoverage(lastKnown)) {
      _target = lastKnown;
      _usesCurrentLocation = true;
      notifyListeners();
    }
    _isLocating = true;
    notifyListeners();
    try {
      final current = await _locationDataSource.resolveCurrentCoordinates();
      if (_initialLocation == null && isWithinCoverage(current)) {
        _target = current;
        _usesCurrentLocation = true;
        _errorMessage = null;
      } else if (_initialLocation == null) {
        // Coverage feedback follows the selected pin, not a background GPS
        // reading that was intentionally ignored.
        _errorMessage = null;
      }
    } on LocationSelectionException catch (error) {
      _setLocationFailure(error);
    } catch (_) {
      _errorMessage =
          'Could not find your current location. Choose one manually.';
    } finally {
      _gateStatus = LocationGateStatus.ready;
      _isLocating = false;
      notifyListeners();
    }
  }

  bool isWithinCoverage(DeviceCoordinates coordinates) =>
      _isWithinCoverage?.call(coordinates) ?? true;

  void selectManual(DeviceCoordinates coordinates) {
    if (!canConfirm) return;
    _target = coordinates;
    _usesCurrentLocation = false;
    _errorMessage = null;
    _formattedAddress = null;
    _placeId = null;
    notifyListeners();
  }

  void selectSearchResult(GeoapifyPlace place) {
    if (!canConfirm) return;
    _target = DeviceCoordinates(place.latitude, place.longitude);
    _usesCurrentLocation = false;
    _errorMessage = null;
    _formattedAddress = place.formattedAddress;
    _placeId = place.placeId;
    notifyListeners();
  }

  void applyReverseResult(
    DeviceCoordinates requestedCoordinates,
    GeoapifyPlace? place,
  ) {
    if (!_sameCoordinates(_target, requestedCoordinates)) return;
    _formattedAddress = place?.formattedAddress;
    _placeId = place?.placeId;
    notifyListeners();
  }

  Future<void> openRequiredSettings() {
    return switch (_gateStatus) {
      LocationGateStatus.permissionDeniedForever =>
        _locationDataSource.openAppSettings(),
      LocationGateStatus.serviceDisabled =>
        _locationDataSource.openLocationSettings(),
      _ => Future<void>.value(),
    };
  }

  void _setLocationFailure(LocationSelectionException error) {
    _usesCurrentLocation = false;
    _errorMessage = error.message;
    _gateStatus = LocationGateStatus.ready;
  }

  bool _sameCoordinates(DeviceCoordinates first, DeviceCoordinates second) =>
      (first.latitude - second.latitude).abs() < 0.0000001 &&
      (first.longitude - second.longitude).abs() < 0.0000001;
}

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

  final DeviceLocationDataSource locationDataSource;
  final MapGeocodingDataSource geocodingDataSource;
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
  List<GeoapifyPlace> _searchResults = const [];
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

  void _selectSearchResult(GeoapifyPlace place) {
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

  DeviceCoordinates placeCoordinates(GeoapifyPlace place) =>
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
          ? const _MissingMapConfiguration()
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
    return Column(
      key: const ValueKey('map-picker-map-page'),
      children: [
        _PickerHeader(
          title: context.tr('Delivery address'),
          onClose: () => Navigator.maybePop(context),
          onSearch: _openSearch,
        ),
        Expanded(child: _buildMap()),
      ],
    );
  }

  Widget _buildMap() {
    final target = _selectionController.target;
    final isInsideCity = _isWithinSelectedCity(_selectionController.target);
    final formattedAddress = _selectionController.formattedAddress?.trim();
    final locationLabel = formattedAddress?.isNotEmpty == true
        ? formattedAddress!
        : widget.selectedCity?.displayName(
            arabic: Localizations.localeOf(context).languageCode != 'en',
          );
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(target.latitude, target.longitude),
              initialZoom: 16,
              minZoom: 4,
              maxZoom: MapTilerMapConfig.maxZoom,
              onMapReady: () {
                _mapReady = true;
                _moveMap(_selectionController.target, zoom: 16);
              },
              onMapEvent: _onMapEvent,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    widget.tileUrlTemplateOverride ??
                    MapTilerMapConfig.tileUrl(),
                userAgentPackageName: MapTilerMapConfig.userAgentPackageName,
                tileProvider: _tileProvider,
                maxNativeZoom: 20,
                maxZoom: MapTilerMapConfig.maxZoom,
                panBuffer: 1,
                keepBuffer: 2,
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'MapTiler',
                    onTap: () => _openUrl('https://www.maptiler.com/'),
                  ),
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () =>
                        _openUrl('https://www.openstreetmap.org/copyright'),
                  ),
                ],
              ),
            ],
          ),
        ),
        IgnorePointer(
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, -48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PinDeliveryBubble(
                    text: context.tr(
                      isInsideCity
                          ? 'Your order will be delivered to this location'
                          : 'Outside the delivery area. Adjust the location.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const _MapPin(),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _LocationConfirmationPanel(
                locationLabel: locationLabel,
                onConfirm: isInsideCity ? _confirm : null,
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: locationLabel?.isNotEmpty == true ? 142 : 98,
          child: _CompactMapButton(
            key: const ValueKey('map-picker-current-location'),
            onPressed: _selectionController.isLoading
                ? null
                : _moveToCurrentLocation,
            icon: Icons.my_location_rounded,
            tooltip: context.tr('Current location'),
          ),
        ),
      ],
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
                _CompactMapButton(
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
    return SizedBox(
      height: 48,
      child: TextField(
        key: const ValueKey('map-picker-search-field'),
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: context.tr('Search for a place in Egypt'),
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 23,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                    _searchFocus.requestFocus();
                  },
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_isSearching) {
      return const _SearchLoadingList();
    }
    if (_searchFailed) {
      return Center(
        child: _SearchMessage(
          message: context.tr('Place search failed.'),
          actionLabel: context.tr('Retry'),
          onAction: _retrySearch,
        ),
      );
    }
    if (_searchResults.isNotEmpty) {
      return ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _searchResults.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 20, endIndent: 20),
        itemBuilder: (context, index) {
          final place = _searchResults[index];
          return _SearchResultTile(
            place: place,
            onTap: () => _selectSearchResult(place),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _PickerHeader extends StatelessWidget {
  const _PickerHeader({
    required this.title,
    required this.onClose,
    required this.onSearch,
  });

  final String title;
  final VoidCallback onClose;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
          ),
        ),
      ),
      child: Row(
        children: [
          _PickerHeaderButton(
            key: const ValueKey('map-picker-close'),
            onPressed: onClose,
            icon: Directionality.of(context) == TextDirection.rtl
                ? AppIcons.arrow_right_3
                : AppIcons.arrow_left_2,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: AppFontSizes.sectionTitle,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          _PickerHeaderButton(
            key: const ValueKey('map-picker-search-open'),
            onPressed: onSearch,
            icon: AppIcons.search_normal,
            tooltip: MaterialLocalizations.of(context).searchFieldLabel,
          ),
        ],
      ),
    );
  }
}

class _PickerHeaderButton extends StatelessWidget {
  const _PickerHeaderButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(
        dimension: 44,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 21, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _CompactMapButton extends StatelessWidget {
  const _CompactMapButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.elevation = 4,
    this.borderColor,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final double elevation;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: elevation,
      shadowColor: const Color(0x33000000),
      shape: CircleBorder(
        side: BorderSide(color: borderColor ?? Colors.transparent),
      ),
      child: SizedBox.square(
        dimension: 40,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon, size: 21),
          color: Theme.of(context).colorScheme.onSurface,
          disabledColor: Theme.of(context).disabledColor,
        ),
      ),
    );
  }
}

class _PinDeliveryBubble extends StatelessWidget {
  const _PinDeliveryBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ),
        const CustomPaint(size: Size(18, 8), painter: _BubbleArrowPainter()),
      ],
    );
  }
}

class _BubbleArrowPainter extends CustomPainter {
  const _BubbleArrowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF242424));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 54,
      height: 68,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 47,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x44000000),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 18),
            ),
          ),
          Icon(
            Icons.location_pin,
            color: AppColors.primary,
            size: 58,
            shadows: [
              Shadow(
                color: Color(0x55000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          Positioned(
            top: 17,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationConfirmationPanel extends StatelessWidget {
  const _LocationConfirmationPanel({
    required this.locationLabel,
    required this.onConfirm,
  });

  final String? locationLabel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('map-picker-bottom-panel'),
      color: Theme.of(context).colorScheme.surface,
      elevation: 10,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locationLabel?.isNotEmpty == true) ...[
                Row(
                  children: [
                    const Icon(
                      AppIcons.location,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationLabel!,
                        key: const ValueKey('map-picker-location-label'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: AppFontSizes.body,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                key: const ValueKey('map-picker-confirm-button'),
                width: double.infinity,
                height: 46,
                child: AppActionButton(
                  label: 'Continue with this location',
                  onPressed: onConfirm,
                  fullWidth: true,
                  horizontalPadding: 22,
                  verticalPadding: 10,
                  textStyle: const TextStyle(
                    fontSize: AppFontSizes.bodyLarge,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.place, required this.onTap});

  final GeoapifyPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      place.addressLine1 ?? place.displayAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (place.addressLine2?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        place.addressLine2!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.north_west_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchLoadingList extends StatelessWidget {
  const _SearchLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: 5,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0xFFF0F1F3)),
      itemBuilder: (_, _) => const SizedBox(
        height: 76,
        child: Row(
          children: [
            _SkeletonBlock(width: 42, height: 42, radius: 21),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(width: 190, height: 13, radius: 7),
                  SizedBox(height: 9),
                  _SkeletonBlock(width: 130, height: 11, radius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        dense: true,
        title: Text(message),
        trailing: TextButton(onPressed: onAction, child: Text(actionLabel)),
      ),
    );
  }
}

class _MissingMapConfiguration extends StatelessWidget {
  const _MissingMapConfiguration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.tr(
            'Map configuration is unavailable. Please try again later.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
