import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/config/app_map_tile_provider.dart';
import '../../../../../core/config/maptiler_map_config.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/icons/app_icons.dart';
import '../../../../../core/localization/app_translations.dart';
import '../../../location/domain/services/device_location_service.dart';
import '../views/address/address_location_picker_view.dart';

class AddressPageHeader extends StatelessWidget {
  const AddressPageHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            context.tr(title),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: AppFontSizes.bodyLarge,
              fontWeight: FontWeight.w900,
            ),
          ),
          PositionedDirectional(
            start: 0,
            child: SizedBox.square(
              dimension: 42,
              child: Material(
                color: Colors.transparent,
                shape: CircleBorder(
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onBack,
                  iconSize: 22,
                  icon: Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddressMapPreview extends StatefulWidget {
  const AddressMapPreview({
    super.key,
    required this.location,
    required this.fallback,
    required this.onTap,
  });

  final SelectedMapLocation? location;
  final DeviceCoordinates fallback;
  final VoidCallback onTap;

  @override
  State<AddressMapPreview> createState() => AddressMapPreviewState();
}

class AddressMapPreviewState extends State<AddressMapPreview> {
  late final NetworkTileProvider _tileProvider;

  @override
  void initState() {
    super.initState();
    _tileProvider = createAppMapTileProvider();
  }

  @override
  Widget build(BuildContext context) {
    final coordinates = widget.location?.coordinates ?? widget.fallback;
    return Semantics(
      button: true,
      label: context.tr('Choose location on map'),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 104,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (MapTilerMapConfig.isConfigured)
                  IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          coordinates.latitude,
                          coordinates.longitude,
                        ),
                        initialZoom: 14,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: MapTilerMapConfig.tileUrl(),
                          userAgentPackageName:
                              MapTilerMapConfig.userAgentPackageName,
                          tileProvider: _tileProvider,
                          maxNativeZoom: 20,
                          panBuffer: 0,
                          keepBuffer: 1,
                        ),
                      ],
                    ),
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.map_outlined,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                  ),
                const Center(
                  child: Icon(
                    Icons.location_pin,
                    color: AppColors.primary,
                    size: 40,
                    shadows: [
                      Shadow(
                        color: Color(0x44000000),
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddressTypeSelector extends StatelessWidget {
  const AddressTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const types = [
      ('apartment', 'Apartment', AppIcons.building_31),
      ('house', 'House', AppIcons.home),
      ('office', 'Office', AppIcons.bag_2),
    ];
    return Row(
      children: [
        for (var index = 0; index < types.length; index++) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: AddressTypeButton(
              selected: value == types[index].$1,
              icon: types[index].$3,
              label: context.tr(types[index].$2),
              onTap: () => onChanged(types[index].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class AddressTypeButton extends StatelessWidget {
  const AddressTypeButton({
    super.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? AppColors.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: selected ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: AppFontSizes.body,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
