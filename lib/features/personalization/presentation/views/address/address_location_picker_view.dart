import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/maptiler_map_config.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../location/data/datasources/device_location_data_source.dart';
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
  }) : _locationDataSource = locationDataSource,
       _initialLocation = initialLocation,
       _target = initialLocation?.coordinates ?? fallbackCoordinates,
       _formattedAddress = initialLocation?.formattedAddress,
       _placeId = initialLocation?.placeId;

  final DeviceLocationDataSource _locationDataSource;
  final SelectedMapLocation? _initialLocation;
  DeviceCoordinates _target;
  LocationGateStatus _gateStatus = LocationGateStatus.checking;
  bool _usesCurrentLocation = false;
  String? _errorMessage;
  String? _formattedAddress;
  String? _placeId;

  DeviceCoordinates get target => _target;
  LocationGateStatus get gateStatus => _gateStatus;
  bool get isLoading => _gateStatus == LocationGateStatus.checking;
  bool get canConfirm => _gateStatus == LocationGateStatus.ready;
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
    _gateStatus = LocationGateStatus.checking;
    notifyListeners();
    try {
      final current = await _locationDataSource.resolveCurrentCoordinates();
      if (_initialLocation == null) {
        _target = current;
        _usesCurrentLocation = true;
      }
      _gateStatus = LocationGateStatus.ready;
      _errorMessage = null;
      return _target;
    } on LocationSelectionException catch (error) {
      _setLocationFailure(error);
      return null;
    } catch (_) {
      _gateStatus = LocationGateStatus.unavailable;
      _errorMessage = 'Could not find your current location. Try again.';
      return null;
    } finally {
      notifyListeners();
    }
  }

  Future<DeviceCoordinates?> useCurrentLocation() async {
    _gateStatus = LocationGateStatus.checking;
    notifyListeners();
    try {
      final coordinates = await _locationDataSource.resolveCurrentCoordinates();
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
      notifyListeners();
    }
  }

  void selectManual(DeviceCoordinates coordinates) {
    if (!canConfirm) return;
    _target = coordinates;
    _usesCurrentLocation = false;
    _formattedAddress = null;
    _placeId = null;
    notifyListeners();
  }

  void selectSearchResult(GeoapifyPlace place) {
    if (!canConfirm) return;
    _target = DeviceCoordinates(place.latitude, place.longitude);
    _usesCurrentLocation = false;
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
    _gateStatus = switch (error.reason) {
      LocationSelectionFailure.permissionDenied =>
        LocationGateStatus.permissionDenied,
      LocationSelectionFailure.permissionDeniedForever =>
        LocationGateStatus.permissionDeniedForever,
      LocationSelectionFailure.serviceDisabled =>
        LocationGateStatus.serviceDisabled,
      _ => LocationGateStatus.unavailable,
    };
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
    this.initialLocation,
    this.tileUrlTemplateOverride,
  });

  final DeviceLocationDataSource locationDataSource;
  final MapGeocodingDataSource geocodingDataSource;
  final DeviceCoordinates fallbackCoordinates;
  final SelectedMapLocation? initialLocation;
  final String? tileUrlTemplateOverride;

  @override
  State<AddressLocationPickerView> createState() =>
      _AddressLocationPickerViewState();
}

class _AddressLocationPickerViewState extends State<AddressLocationPickerView>
    with WidgetsBindingObserver {
  late final AddressLocationPickerController _selectionController;
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
  bool _reverseFailed = false;
  bool _mapReady = false;
  bool _searchMode = false;

  String get _language =>
      Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectionController = AddressLocationPickerController(
      locationDataSource: widget.locationDataSource,
      fallbackCoordinates: widget.fallbackCoordinates,
      initialLocation: widget.initialLocation,
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
    if (mounted) setState(() {});
  }

  Future<void> _moveToCurrentLocation() async {
    final coordinates = await _selectionController.useCurrentLocation();
    if (!mounted || coordinates == null) return;
    _moveMap(coordinates, zoom: 16);
    _scheduleReverse(coordinates);
  }

  void _moveMap(DeviceCoordinates coordinates, {double? zoom}) {
    if (!_mapReady) return;
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
    if (event is MapEventMove ||
        event is MapEventMoveEnd ||
        event is MapEventFlingAnimation) {
      final center = event.camera.center;
      final coordinates = DeviceCoordinates(center.latitude, center.longitude);
      _selectionController.selectManual(coordinates);
      _scheduleReverse(coordinates);
    }
  }

  void _scheduleReverse(DeviceCoordinates coordinates) {
    _reverseDebounce?.cancel();
    final generation = ++_reverseGeneration;
    _reverseFailed = false;
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
      setState(() => _reverseFailed = false);
    } catch (_) {
      if (!mounted || generation != _reverseGeneration) return;
      setState(() => _reverseFailed = true);
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
      _reverseFailed = false;
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
    if (!_selectionController.canConfirm) return;
    Navigator.pop(context, _selectionController.selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body:
          !MapTilerMapConfig.isConfigured &&
              widget.tileUrlTemplateOverride == null
          ? const _MissingMapConfiguration()
          : _selectionController.canConfirm
          ? SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _searchMode ? _buildSearchPage() : _buildMapPage(),
              ),
            )
          : _LocationGate(
              status: _selectionController.gateStatus,
              message: _selectionController.errorMessage,
              onRetry: _initializeLocation,
              onOpenSettings: () async {
                await _selectionController.openRequiredSettings();
              },
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
    final highDensity = MediaQuery.devicePixelRatioOf(context) >= 2;
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
                    MapTilerMapConfig.tileUrl(highDensity: highDensity),
                userAgentPackageName: MapTilerMapConfig.userAgentPackageName,
                maxNativeZoom: 20,
                maxZoom: MapTilerMapConfig.maxZoom,
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
              offset: const Offset(0, -22),
              child: const _MapPin(),
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
                address: _selectionController.formattedAddress,
                failed: _reverseFailed,
                onRetry: () {
                  final coordinates = _selectionController.target;
                  _scheduleReverse(coordinates);
                },
                onConfirm: _confirm,
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 156,
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
      color: Colors.white,
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
                  borderColor: const Color(0xFFE4E7EC),
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildSearchField()),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFECEEF2)),
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
        style: const TextStyle(
          color: Color(0xFF1D2939),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: context.tr('Search for a place in Egypt'),
          hintStyle: const TextStyle(
            color: Color(0xFF98A2B3),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF667085),
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
                  color: const Color(0xFF475467),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                ),
          filled: true,
          fillColor: const Color(0xFFF5F6F8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
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
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFECEEF2))),
      ),
      child: Row(
        children: [
          _CompactMapButton(
            key: const ValueKey('map-picker-close'),
            onPressed: onClose,
            icon: Icons.close_rounded,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            elevation: 0,
            borderColor: const Color(0xFFE4E7EC),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _CompactMapButton(
            key: const ValueKey('map-picker-search-open'),
            onPressed: onSearch,
            icon: Icons.search_rounded,
            tooltip: MaterialLocalizations.of(context).searchFieldLabel,
            elevation: 0,
            borderColor: const Color(0xFFE4E7EC),
          ),
        ],
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
      color: Colors.white,
      elevation: elevation,
      shadowColor: const Color(0x33000000),
      shape: CircleBorder(
        side: BorderSide(color: borderColor ?? Colors.transparent),
      ),
      child: SizedBox.square(
        dimension: 44,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: Icon(icon, size: 23),
          color: const Color(0xFF1D2939),
          disabledColor: const Color(0xFF98A2B3),
        ),
      ),
    );
  }
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
    required this.address,
    required this.failed,
    required this.onRetry,
    required this.onConfirm,
  });

  final String? address;
  final bool failed;
  final VoidCallback onRetry;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final displayAddress = context.tr(
      failed
          ? 'Address lookup failed. You can still continue.'
          : address?.trim().isNotEmpty == true
          ? address!
          : 'Finding the address...',
    );
    return Material(
      key: const ValueKey('map-picker-bottom-panel'),
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF344054),
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (failed)
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(context.tr('Retry')),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: SizedBox(
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
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
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
                      style: const TextStyle(
                        color: Color(0xFF1D2939),
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
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.north_west_rounded,
                color: Color(0xFF98A2B3),
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

class _LocationGate extends StatelessWidget {
  const _LocationGate({
    required this.status,
    required this.message,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final LocationGateStatus status;
  final String? message;
  final Future<void> Function() onRetry;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    if (status == LocationGateStatus.checking) {
      return const Center(child: CircularProgressIndicator());
    }
    final opensSettings =
        status == LocationGateStatus.permissionDeniedForever ||
        status == LocationGateStatus.serviceDisabled;
    final action = status == LocationGateStatus.permissionDeniedForever
        ? 'Open app settings'
        : status == LocationGateStatus.serviceDisabled
        ? 'Open location settings'
        : 'Retry';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 18),
            Text(
              context.tr(
                message ??
                    'Location access is required before choosing an address.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: opensSettings ? onOpenSettings : onRetry,
              icon: Icon(opensSettings ? Icons.settings : Icons.refresh),
              label: Text(context.tr(action)),
            ),
          ],
        ),
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
