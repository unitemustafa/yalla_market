import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:maplibre/maplibre.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../../location/data/datasources/device_location_data_source.dart';
import '../../../../location/domain/entities/city_data.dart';
import '../../../../location/presentation/cubit/location_cubit.dart';
import '../../../domain/entities/address.dart';

class AddressMapPickerView extends StatefulWidget {
  const AddressMapPickerView({super.key, this.initialAddress});

  final AddressData? initialAddress;

  @override
  State<AddressMapPickerView> createState() => _AddressMapPickerViewState();
}

class _AddressMapPickerViewState extends State<AddressMapPickerView> {
  static const _mapStyleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  MapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final Geocoding _geocoding = Geocoding();
  late Geographic _target;
  PointResolution? _resolution;
  bool _isResolving = false;
  bool _isSearching = false;
  String? _error;
  String _formattedAddress = '';
  String _governorate = '';
  String _district = '';
  int _requestSerial = 0;

  CityData get _selectedCity {
    final state = context.read<LocationCubit>().state;
    final selected = state.selectedCity ?? CityData.general;
    for (final city in state.availableCities) {
      if (selected.serviceCityId != null &&
          city.serviceCityId == selected.serviceCityId) {
        return city.withSource(selected.source);
      }
    }
    return selected;
  }

  @override
  void initState() {
    super.initState();
    final address = widget.initialAddress;
    _target = Geographic(
      lon: address?.longitude ?? 31.2357,
      lat: address?.latitude ?? 30.0444,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        var city = _selectedCity;
        if (!city.isGeneral &&
            city.centerLatitude == null &&
            city.boundaryBbox == null) {
          await context.read<LocationCubit>().loadAvailableCities();
          if (!mounted) return;
          city = _selectedCity;
          setState(() {});
        }
        final cityCenter = _cityCenter(city);
        if (address?.latitude == null && cityCenter != null) {
          _target = cityCenter;
          _mapController?.moveCamera(center: _target);
        }
        _resolveTarget();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city = _selectedCity;
    final mapBounds = _mapBounds(city);
    final polygons = _cityPolygons(city);

    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد الموقع')),
      body: Stack(
        children: [
          MapLibreMap(
            options: MapOptions(
              initStyle: _mapStyleUrl,
              initCenter: _target,
              initZoom: city.isGeneral ? 6.2 : 12,
              minZoom: city.isGeneral ? 5.5 : 9,
              maxZoom: 20,
              maxBounds: mapBounds,
              androidTextureMode: true,
              androidForegroundLoadColor: Theme.of(
                context,
              ).scaffoldBackgroundColor,
            ),
            onMapCreated: _onMapCreated,
            onEvent: _onMapEvent,
            layers: [
              if (polygons.isNotEmpty)
                PolygonLayer(
                  polygons: polygons,
                  color: const Color(0x1A5B8DEF),
                  outlineColor: const Color(0xFF4477CC),
                ),
            ],
            children: const [
              SourceAttribution(
                showMapLibre: true,
                padding: EdgeInsets.only(right: 8, bottom: 180),
              ),
            ],
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 38),
                child: Icon(
                  Icons.location_pin,
                  color: Color(0xFFFF5A00),
                  size: 58,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(14),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchAddress(),
                decoration: InputDecoration(
                  hintText: 'ابحث عن شارع أو منطقة',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed: _searchAddress,
                          icon: const Icon(Icons.arrow_forward),
                        ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 86,
            left: 16,
            right: 16,
            child: _ResolutionBanner(
              city: city,
              resolution: _resolution,
              isLoading: _isResolving,
              error: _error,
            ),
          ),
          Positioned(
            left: 16,
            bottom: 112,
            child: FloatingActionButton.small(
              heroTag: 'address-current-location',
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: AppActionButton(
                label: 'أدخل العنوان بالكامل',
                onPressed: _resolution?.allowed == true && !_isResolving
                    ? _confirm
                    : null,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveTarget() async {
    final serial = ++_requestSerial;
    setState(() {
      _isResolving = true;
      _error = null;
    });
    try {
      final data = await sl<ApiClient>().post<Map<String, dynamic>>(
        '/locations/resolve-point/',
        data: {'latitude': _target.lat, 'longitude': _target.lon},
      );
      if (!mounted || serial != _requestSerial) return;
      setState(() {
        _resolution = PointResolution.fromJson(data);
        _isResolving = false;
      });
      _reverseGeocodeTarget(serial);
    } on DioException catch (error) {
      if (!mounted || serial != _requestSerial) return;
      final data = error.response?.data;
      final resolution = data is Map<String, dynamic>
          ? PointResolution.fromJson(data)
          : null;
      setState(() {
        _resolution = resolution;
        _error = resolution == null ? 'تعذر التحقق من الموقع' : null;
        _isResolving = false;
      });
    } catch (_) {
      if (!mounted || serial != _requestSerial) return;
      setState(() {
        _error = 'تعذر التحقق من الموقع';
        _isResolving = false;
      });
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _isSearching) return;
    setState(() => _isSearching = true);
    try {
      final results = await _geocoding.locationFromAddress(
        '$query, Egypt',
        locale: const Locale('ar', 'EG'),
      );
      if (!mounted || results.isEmpty) return;
      final result = results.first;
      await _mapController?.animateCamera(
        center: Geographic(lon: result.longitude, lat: result.latitude),
        zoom: 16,
        nativeDuration: const Duration(milliseconds: 600),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم نتمكن من العثور على هذا العنوان')),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _reverseGeocodeTarget(int serial) async {
    try {
      final results = await _geocoding.placemarkFromCoordinates(
        _target.lat,
        _target.lon,
        locale: const Locale('ar', 'EG'),
      );
      if (!mounted || serial != _requestSerial || results.isEmpty) return;
      final place = results.first;
      final parts = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty);
      setState(() {
        _formattedAddress = parts.cast<String>().join('، ');
        _governorate = place.administrativeArea?.trim() ?? '';
        _district = place.subLocality?.trim() ?? place.locality?.trim() ?? '';
      });
    } catch (_) {
      // A readable address is helpful but coordinates remain authoritative.
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final coordinates = await sl<DeviceLocationDataSource>()
          .resolveCurrentCoordinates();
      final target = Geographic(
        lon: coordinates.longitude,
        lat: coordinates.latitude,
      );
      await _mapController?.animateCamera(
        center: target,
        zoom: _selectedCity.isGeneral ? 14 : 16,
        nativeDuration: const Duration(milliseconds: 600),
      );
    } on LocationSelectionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _confirm() {
    final resolution = _resolution;
    if (resolution == null || !resolution.allowed) return;
    final existing = widget.initialAddress;
    Navigator.pop(
      context,
      AddressData(
        id: existing?.id ?? '',
        name: existing?.name ?? '',
        phoneNumber: existing?.phoneNumber ?? '',
        street: existing?.street ?? '',
        postalCode: existing?.postalCode ?? '',
        city: resolution.serviceCityName ?? _selectedCity.name,
        district:
            resolution.deliveryAreaName ??
            (_district.isNotEmpty ? _district : existing?.district ?? ''),
        state: existing?.state ?? '',
        country: existing?.country ?? 'Egypt',
        latitude: _target.lat,
        longitude: _target.lon,
        isDefault: existing?.isDefault ?? false,
        manualCity: resolution.serviceCityId == null
            ? existing?.manualCity
            : null,
        manualArea: resolution.deliveryAreaId == null
            ? existing?.manualArea
            : null,
        serviceCityId: resolution.serviceCityId,
        serviceCityName: resolution.serviceCityName,
        deliveryAreaId: resolution.deliveryAreaId,
        deliveryAreaName: resolution.deliveryAreaName,
        deliveryAreaPrice: resolution.deliveryPrice,
        deliveryType: 'delivery',
        addressType: existing?.addressType ?? 'apartment',
        recipientName: existing?.recipientName ?? '',
        buildingName: existing?.buildingName ?? '',
        apartmentNumber: existing?.apartmentNumber ?? '',
        floor: existing?.floor ?? '',
        companyName: existing?.companyName ?? '',
        additionalInstructions: existing?.additionalInstructions ?? '',
        label: existing?.label ?? '',
        formattedAddress: _formattedAddress.isNotEmpty
            ? _formattedAddress
            : existing?.formattedAddress ?? '',
        placeId: existing?.placeId ?? '',
        governorate: _governorate.isNotEmpty
            ? _governorate
            : existing?.governorate ?? '',
        fulfillmentType: resolution.fulfillmentType,
        etaMinMinutes: resolution.etaMinMinutes,
        etaMaxMinutes: resolution.etaMaxMinutes,
      ),
    );
  }

  void _onMapCreated(MapController controller) async {
    _mapController = controller;
    await controller.moveCamera(center: _target);
    if (!MapController.userLocationIsSupported) return;
    try {
      await controller.enableLocation();
    } catch (_) {
      // The custom location button still handles denied permissions.
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveCamera) {
      _target = event.camera.center;
    } else if (event is MapEventCameraIdle) {
      _resolveTarget();
    }
  }

  LngLatBounds _mapBounds(CityData city) {
    final bbox = city.boundaryBbox;
    if (bbox != null && bbox.length == 4) {
      return LngLatBounds(
        longitudeWest: bbox[0],
        latitudeSouth: bbox[1],
        longitudeEast: bbox[2],
        latitudeNorth: bbox[3],
      );
    }
    if (city.centerLatitude != null &&
        city.centerLongitude != null &&
        city.radiusKm != null) {
      final latitudeDelta = city.radiusKm! / 111.32;
      final longitudeDelta =
          city.radiusKm! /
          (111.32 *
              math.max(
                math.cos(city.centerLatitude! * math.pi / 180).abs(),
                0.01,
              ));
      return LngLatBounds(
        longitudeWest: city.centerLongitude! - longitudeDelta,
        latitudeSouth: city.centerLatitude! - latitudeDelta,
        longitudeEast: city.centerLongitude! + longitudeDelta,
        latitudeNorth: city.centerLatitude! + latitudeDelta,
      );
    }
    return const LngLatBounds(
      longitudeWest: 22,
      latitudeSouth: 21.5,
      longitudeEast: 37,
      latitudeNorth: 31.8,
    );
  }

  Geographic? _cityCenter(CityData city) {
    if (city.centerLatitude != null && city.centerLongitude != null) {
      return Geographic(lon: city.centerLongitude!, lat: city.centerLatitude!);
    }
    final bbox = city.boundaryBbox;
    if (bbox == null || bbox.length != 4) return null;
    return Geographic(
      lon: (bbox[0] + bbox[2]) / 2,
      lat: (bbox[1] + bbox[3]) / 2,
    );
  }

  List<Feature<Polygon>> _cityPolygons(CityData city) {
    final geojson = city.boundaryGeojson;
    if (geojson == null) {
      final centerLatitude = city.centerLatitude;
      final centerLongitude = city.centerLongitude;
      final radiusKm = city.radiusKm;
      if (centerLatitude == null ||
          centerLongitude == null ||
          radiusKm == null ||
          radiusKm <= 0) {
        return const [];
      }
      final longitudeScale = math.max(
        math.cos(centerLatitude * math.pi / 180).abs(),
        0.01,
      );
      final coordinates = List.generate(65, (index) {
        final angle = 2 * math.pi * index / 64;
        return Geographic(
          lon:
              centerLongitude +
              (radiusKm / (111.32 * longitudeScale)) * math.cos(angle),
          lat: centerLatitude + (radiusKm / 111.32) * math.sin(angle),
        );
      });
      return [
        Feature(geometry: Polygon.from([coordinates])),
      ];
    }
    final type = geojson['type'];
    final rawCoordinates = geojson['coordinates'];
    final rings = <List<dynamic>>[];
    if (type == 'Polygon' &&
        rawCoordinates is List &&
        rawCoordinates.isNotEmpty) {
      final outer = rawCoordinates.first;
      if (outer is List) rings.add(outer);
    } else if (type == 'MultiPolygon' && rawCoordinates is List) {
      for (final polygon in rawCoordinates) {
        if (polygon is List && polygon.isNotEmpty && polygon.first is List) {
          rings.add(polygon.first as List<dynamic>);
        }
      }
    }
    return rings
        .map(_polygonFeature)
        .whereType<Feature<Polygon>>()
        .toList(growable: false);
  }

  Feature<Polygon>? _polygonFeature(List<dynamic> ring) {
    final coordinates = ring
        .whereType<List>()
        .where((coordinate) => coordinate.length >= 2)
        .map(
          (coordinate) => Geographic(
            lon: (coordinate[0] as num).toDouble(),
            lat: (coordinate[1] as num).toDouble(),
          ),
        )
        .toList();
    if (coordinates.length < 3) return null;
    if (coordinates.first != coordinates.last) {
      coordinates.add(coordinates.first);
    }
    return Feature(geometry: Polygon.from([coordinates]));
  }
}

class PointResolution {
  const PointResolution({
    required this.allowed,
    required this.reasonCode,
    required this.fulfillmentType,
    this.serviceCityId,
    this.serviceCityName,
    this.deliveryAreaId,
    this.deliveryAreaName,
    this.deliveryPrice,
    this.etaMinMinutes,
    this.etaMaxMinutes,
  });

  final bool allowed;
  final String? reasonCode;
  final String? fulfillmentType;
  final int? serviceCityId;
  final String? serviceCityName;
  final int? deliveryAreaId;
  final String? deliveryAreaName;
  final double? deliveryPrice;
  final int? etaMinMinutes;
  final int? etaMaxMinutes;

  factory PointResolution.fromJson(Map<String, dynamic> json) {
    final city = json['service_city'];
    final area = json['delivery_area'];
    return PointResolution(
      allowed: json['allowed'] == true,
      reasonCode: json['reason_code']?.toString(),
      fulfillmentType: json['fulfillment_type']?.toString(),
      serviceCityId: _intValue(city is Map ? city['id'] : null),
      serviceCityName: city is Map ? city['name']?.toString() : null,
      deliveryAreaId: _intValue(area is Map ? area['id'] : null),
      deliveryAreaName: area is Map ? area['name']?.toString() : null,
      deliveryPrice: _doubleValue(json['delivery_price']),
      etaMinMinutes: _intValue(json['eta_min_minutes']),
      etaMaxMinutes: _intValue(json['eta_max_minutes']),
    );
  }
}

class _ResolutionBanner extends StatelessWidget {
  const _ResolutionBanner({
    required this.city,
    required this.resolution,
    required this.isLoading,
    required this.error,
  });

  final CityData city;
  final PointResolution? resolution;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final resolution = this.resolution;
    String message;
    Color color;
    if (isLoading) {
      message = 'جارٍ التحقق من موقع التوصيل...';
      color = Colors.black87;
    } else if (error != null) {
      message = error!;
      color = Colors.red.shade700;
    } else if (resolution?.allowed != true) {
      message = city.isGeneral
          ? 'هذا الموقع غير متاح حاليًا، حرّك الخريطة داخل مصر'
          : 'خارج حدود ${city.name}، قم بتعديل الموقع';
      color = Colors.red.shade700;
    } else if (resolution!.fulfillmentType == 'direct') {
      final price = resolution.deliveryPrice?.toStringAsFixed(0);
      final eta = resolution.etaMinMinutes == null
          ? ''
          : ' • ${resolution.etaMinMinutes}-${resolution.etaMaxMinutes} دقيقة';
      message =
          'توصيل متاح: ${resolution.deliveryAreaName ?? ''}${price == null ? '' : ' • $price ج.م'}$eta';
      color = Colors.green.shade700;
    } else {
      message = 'الموقع متاح عن طريق الشحن الخارجي، وسيتم تأكيد التكلفة';
      color = Colors.orange.shade800;
    }
    return Material(
      elevation: 4,
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            if (isLoading)
              const Padding(
                padding: EdgeInsetsDirectional.only(end: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int? _intValue(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
