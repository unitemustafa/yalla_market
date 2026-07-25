import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../location/data/datasources/device_location_data_source.dart';

class AddressLocationPickerController extends ChangeNotifier {
  AddressLocationPickerController({
    required DeviceLocationDataSource locationDataSource,
    required DeviceCoordinates fallbackCoordinates,
  }) : _locationDataSource = locationDataSource,
       _target = fallbackCoordinates;

  final DeviceLocationDataSource _locationDataSource;
  DeviceCoordinates _target;
  bool _isLoading = true;
  bool _canConfirm = false;
  bool _usesCurrentLocation = false;
  String? _errorMessage;

  DeviceCoordinates get target => _target;
  bool get isLoading => _isLoading;
  bool get canConfirm => _canConfirm;
  bool get usesCurrentLocation => _usesCurrentLocation;
  String? get errorMessage => _errorMessage;

  Future<DeviceCoordinates?> initialize() => useCurrentLocation();

  Future<DeviceCoordinates?> useCurrentLocation() async {
    _isLoading = true;
    notifyListeners();
    try {
      final coordinates = await _locationDataSource.resolveCurrentCoordinates();
      _target = coordinates;
      _canConfirm = true;
      _usesCurrentLocation = true;
      _errorMessage = null;
      return coordinates;
    } on LocationSelectionException catch (error) {
      _canConfirm = false;
      _usesCurrentLocation = false;
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _canConfirm = false;
      _usesCurrentLocation = false;
      _errorMessage =
          'Could not find your current location. Choose one manually.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectManual(DeviceCoordinates coordinates) {
    _target = coordinates;
    _canConfirm = true;
    _usesCurrentLocation = false;
    _errorMessage = null;
    notifyListeners();
  }
}

class AddressLocationPickerView extends StatefulWidget {
  const AddressLocationPickerView({
    super.key,
    required this.locationDataSource,
    required this.fallbackCoordinates,
  });

  final DeviceLocationDataSource locationDataSource;
  final DeviceCoordinates fallbackCoordinates;

  @override
  State<AddressLocationPickerView> createState() =>
      _AddressLocationPickerViewState();
}

class _AddressLocationPickerViewState extends State<AddressLocationPickerView> {
  static const _mapStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  late final AddressLocationPickerController _selectionController;
  MapController? _mapController;
  Geographic? _cameraTarget;
  bool _userGestureInProgress = false;

  @override
  void initState() {
    super.initState();
    _selectionController = AddressLocationPickerController(
      locationDataSource: widget.locationDataSource,
      fallbackCoordinates: widget.fallbackCoordinates,
    )..addListener(_onSelectionChanged);
    _selectionController.initialize();
  }

  @override
  void dispose() {
    _selectionController
      ..removeListener(_onSelectionChanged)
      ..dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _moveToCurrentLocation() async {
    final coordinates = await _selectionController.useCurrentLocation();
    if (!mounted) return;
    if (coordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              _selectionController.errorMessage ??
                  'Could not find your current location. Choose one manually.',
            ),
          ),
        ),
      );
      return;
    }

    await _mapController?.animateCamera(
      center: Geographic(lon: coordinates.longitude, lat: coordinates.latitude),
      zoom: 16,
      nativeDuration: const Duration(milliseconds: 550),
    );
    try {
      await _mapController?.enableLocation();
    } catch (_) {
      // The selected GPS coordinate remains valid if the map's blue-dot layer
      // is unavailable on a specific device.
    }
  }

  void _onMapCreated(MapController controller) {
    _mapController = controller;
    if (!_selectionController.usesCurrentLocation) return;
    controller.enableLocation().catchError((_) {});
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventStartMoveCamera) {
      _userGestureInProgress = event.reason == CameraChangeReason.apiGesture;
      return;
    }
    if (event is MapEventMoveCamera) {
      _cameraTarget = event.camera.center;
      return;
    }
    if (event is MapEventCameraIdle && _userGestureInProgress) {
      _userGestureInProgress = false;
      final target = _cameraTarget;
      if (target == null) return;
      _selectionController.selectManual(
        DeviceCoordinates(target.lat, target.lon),
      );
    }
  }

  void _confirm() {
    if (!_selectionController.canConfirm) return;
    Navigator.pop(context, _selectionController.target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final target = _selectionController.target;

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
      body: _selectionController.isLoading && _mapController == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: MapLibreMap(
                    options: MapOptions(
                      initStyle: _mapStyleUrl,
                      initCenter: Geographic(
                        lon: target.longitude,
                        lat: target.latitude,
                      ),
                      initZoom: 16,
                      minZoom: 4,
                      maxZoom: 20,
                      androidTextureMode: false,
                      androidMode: AndroidPlatformViewMode.hc,
                    ),
                    onMapCreated: _onMapCreated,
                    onEvent: _onMapEvent,
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
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _LocationStatusBanner(
                    canConfirm: _selectionController.canConfirm,
                    usesCurrentLocation:
                        _selectionController.usesCurrentLocation,
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 112,
                  child: SafeArea(
                    top: false,
                    child: FloatingActionButton.small(
                      heroTag: 'address-current-location',
                      onPressed: _selectionController.isLoading
                          ? null
                          : _moveToCurrentLocation,
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      child: _selectionController.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: SafeArea(
                    top: false,
                    child: AppActionButton(
                      label: 'Continue with this location',
                      onPressed: _selectionController.canConfirm
                          ? _confirm
                          : null,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LocationStatusBanner extends StatelessWidget {
  const _LocationStatusBanner({
    required this.canConfirm,
    required this.usesCurrentLocation,
  });

  final bool canConfirm;
  final bool usesCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final message = canConfirm
        ? usesCurrentLocation
              ? 'Your current location is selected. Move the map to adjust it.'
              : 'Location selected manually.'
        : 'Current location is unavailable. Move the map to choose it manually.';
    final color = canConfirm
        ? const Color(0xFF1F7A4D)
        : const Color(0xFF222222);

    return Material(
      elevation: 4,
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          context.tr(message),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
