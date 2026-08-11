import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/config/maptiler_map_config.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/presentation/widgets/buttons/app_action_button.dart';
import '../../../location/domain/services/device_location_service.dart';

class AddressLocationMapPage extends StatelessWidget {
  const AddressLocationMapPage({
    super.key,
    required this.mapController,
    required this.tileProvider,
    required this.target,
    required this.tileUrlTemplate,
    required this.isInsideCity,
    required this.locationLabel,
    required this.title,
    required this.deliveryMessage,
    required this.currentLocationTooltip,
    required this.isLocating,
    required this.onClose,
    required this.onSearch,
    required this.onMapReady,
    required this.onMapEvent,
    required this.onConfirm,
    required this.onCurrentLocation,
    required this.onOpenUrl,
  });

  final MapController mapController;
  final NetworkTileProvider tileProvider;
  final DeviceCoordinates target;
  final String tileUrlTemplate;
  final bool isInsideCity;
  final String? locationLabel;
  final String title;
  final String deliveryMessage;
  final String currentLocationTooltip;
  final bool isLocating;
  final VoidCallback onClose;
  final VoidCallback onSearch;
  final VoidCallback onMapReady;
  final void Function(MapEvent event) onMapEvent;
  final VoidCallback? onConfirm;
  final VoidCallback onCurrentLocation;
  final ValueChanged<String> onOpenUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('map-picker-map-page'),
      children: [
        PickerHeader(title: title, onClose: onClose, onSearch: onSearch),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: LatLng(target.latitude, target.longitude),
                    initialZoom: 16,
                    minZoom: 4,
                    maxZoom: MapTilerMapConfig.maxZoom,
                    onMapReady: onMapReady,
                    onMapEvent: onMapEvent,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: tileUrlTemplate,
                      userAgentPackageName:
                          MapTilerMapConfig.userAgentPackageName,
                      tileProvider: tileProvider,
                      maxNativeZoom: 20,
                      maxZoom: MapTilerMapConfig.maxZoom,
                      panBuffer: 1,
                      keepBuffer: 2,
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'MapTiler',
                          onTap: () => onOpenUrl('https://www.maptiler.com/'),
                        ),
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => onOpenUrl(
                            'https://www.openstreetmap.org/copyright',
                          ),
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
                        PinDeliveryBubble(text: deliveryMessage),
                        const SizedBox(height: 8),
                        const MapPin(),
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
                    child: LocationConfirmationPanel(
                      locationLabel: locationLabel,
                      onConfirm: onConfirm,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: locationLabel?.isNotEmpty == true ? 142 : 98,
                child: CompactMapButton(
                  key: const ValueKey('map-picker-current-location'),
                  onPressed: isLocating ? null : onCurrentLocation,
                  icon: Icons.my_location_rounded,
                  tooltip: currentLocationTooltip,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PickerHeader extends StatelessWidget {
  const PickerHeader({
    super.key,
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

class CompactMapButton extends StatelessWidget {
  const CompactMapButton({
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

class PinDeliveryBubble extends StatelessWidget {
  const PinDeliveryBubble({super.key, required this.text});

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

class MapPin extends StatelessWidget {
  const MapPin({super.key});

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

class LocationConfirmationPanel extends StatelessWidget {
  const LocationConfirmationPanel({
    super.key,
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
