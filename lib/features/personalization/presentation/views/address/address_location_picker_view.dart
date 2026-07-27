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
      _searchResults = const [];
      _searchFailed = false;
      _reverseFailed = false;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: Text(
          context.tr('Confirm delivery location'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body:
          !MapTilerMapConfig.isConfigured &&
              widget.tileUrlTemplateOverride == null
          ? const _MissingMapConfiguration()
          : _selectionController.canConfirm
          ? _buildMap()
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
        const IgnorePointer(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 42),
              child: Icon(
                Icons.location_pin,
                color: AppColors.primary,
                size: 58,
                shadows: [
                  Shadow(
                    color: Color(0x66000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(top: 16, left: 16, right: 16, child: _buildSearch()),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AddressPreview(
                  address: _selectionController.formattedAddress,
                  failed: _reverseFailed,
                  onRetry: () {
                    final coordinates = _selectionController.target;
                    _scheduleReverse(coordinates);
                  },
                ),
                const SizedBox(height: 10),
                AppActionButton(
                  label: 'Continue with this location',
                  onPressed: _confirm,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 156,
          child: SafeArea(
            top: false,
            child: FloatingActionButton.small(
              heroTag: 'address-current-location',
              onPressed: _selectionController.isLoading
                  ? null
                  : _moveToCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.my_location),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Column(
      children: [
        Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(14),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.tr('Search for a place in Egypt'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_searchFailed)
          _SearchMessage(
            message: context.tr('Place search failed.'),
            actionLabel: context.tr('Retry'),
            onAction: _retrySearch,
          )
        else if (!_isSearching && _searchResults.isNotEmpty)
          Material(
            elevation: 5,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(
                      place.addressLine1 ?? place.displayAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: place.addressLine2 == null
                        ? null
                        : Text(
                            place.addressLine2!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () => _selectSearchResult(place),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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

class _AddressPreview extends StatelessWidget {
  const _AddressPreview({
    required this.address,
    required this.failed,
    required this.onRetry,
  });

  final String? address;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr(
                  failed
                      ? 'Address lookup failed. You can still continue.'
                      : address?.trim().isNotEmpty == true
                      ? address!
                      : 'Finding the address...',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (failed)
              TextButton(onPressed: onRetry, child: Text(context.tr('Retry'))),
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
