import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_media_specs.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/presentation/media/app_video.dart';
import '../../../../core/presentation/widgets/images/app_image.dart';
import '../../domain/entities/home_campaign_data.dart';

enum HomeCampaignSheetResult { dismissed, acted }

Future<HomeCampaignSheetResult?> showHomeCampaignSheet(
  BuildContext context,
  HomeCampaignData campaign, {
  String? imageUrl,
}) {
  return showDialog<HomeCampaignSheetResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    builder: (_) => _HomeCampaignSheet(campaign: campaign, imageUrl: imageUrl),
  );
}

class _HomeCampaignSheet extends StatelessWidget {
  const _HomeCampaignSheet({required this.campaign, this.imageUrl});

  final HomeCampaignData campaign;
  final String? imageUrl;

  double _heightFactor() => switch (campaign.sheet.size) {
    'medium' => 0.58,
    'near_full' => 0.94,
    _ => 0.76,
  };

  @override
  Widget build(BuildContext context) {
    final sheet = campaign.sheet;
    final colorScheme = Theme.of(context).colorScheme;
    final sheetBackgroundColor = sheet.useThemeColors
        ? colorScheme.surface
        : Color(sheet.backgroundColorValue);
    final sheetTextColor = sheet.useThemeColors
        ? colorScheme.onSurface
        : Color(sheet.textColorValue);
    final alignment = sheet.alignment == 'center'
        ? TextAlign.center
        : TextAlign.start;
    final content = _CampaignTextContent(
      campaign: campaign,
      textAlign: alignment,
      textColor: sheetTextColor,
    );
    final screenHeight = MediaQuery.sizeOf(context).height;
    final availableHeight =
        screenHeight - MediaQuery.paddingOf(context).vertical - 48;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: math.min(screenHeight * _heightFactor(), availableHeight),
        ),
        child: ClipRRect(
          key: const ValueKey('home_campaign_surface'),
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(color: sheetBackgroundColor),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 4),
                    child: Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          tooltip: 'إغلاق',
                          onPressed: () => Navigator.pop(
                            context,
                            HomeCampaignSheetResult.dismissed,
                          ),
                          icon: const Icon(Icons.close_rounded),
                          color: sheetTextColor,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final hasMedia =
                            campaign.media.type == 'video' ||
                            (campaign.media.type == 'image' &&
                                (imageUrl ?? campaign.media.imageUrl)
                                    .trim()
                                    .isNotEmpty);
                        final textScale =
                            MediaQuery.textScalerOf(context).scale(24) / 24;
                        // Keep enough room for readable text beside the media,
                        // including when the system font size is increased.
                        final useSplit =
                            sheet.template == 'split' &&
                            hasMedia &&
                            (constraints.maxWidth - 14) / 2 >= 240 * textScale;
                        if (useSplit) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _CampaignMedia(
                                  campaign.media,
                                  imageUrl: imageUrl,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: content),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (hasMedia) ...[
                              _CampaignMedia(
                                campaign.media,
                                imageUrl: imageUrl,
                              ),
                              const SizedBox(height: 18),
                            ],
                            content,
                          ],
                        );
                      },
                    ),
                  ),
                  if (campaign.action.hasButton)
                    SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            backgroundColor: Color(
                              sheet.buttonBackgroundColorValue,
                            ),
                            foregroundColor: Color(sheet.buttonTextColorValue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.pop(
                            context,
                            HomeCampaignSheetResult.acted,
                          ),
                          child: Text(
                            campaign.action.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CampaignTextContent extends StatelessWidget {
  const _CampaignTextContent({
    required this.campaign,
    required this.textAlign,
    required this.textColor,
  });
  final HomeCampaignData campaign;
  final TextAlign textAlign;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          campaign.sheet.title,
          textAlign: textAlign,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.3,
          ),
        ),
        if (campaign.sheet.description.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            campaign.sheet.description,
            textAlign: textAlign,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.78),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.65,
            ),
          ),
        ],
      ],
    );
  }
}

class _CampaignMedia extends StatelessWidget {
  const _CampaignMedia(this.media, {this.imageUrl});
  final HomeCampaignMediaData media;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (media.type == 'video') {
      return _CampaignVideo(media: media);
    }
    final selectedUrl = imageUrl ?? media.imageUrl;
    if (media.type != 'image' || selectedUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return AspectRatio(
      key: const ValueKey('campaign_image_viewport'),
      aspectRatio: AppMediaSpecs.campaignMediaAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AppImage(
          source: selectedUrl,
          fallbackType: AppImagePlaceholderType.offer,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _CampaignVideo extends StatelessWidget {
  const _CampaignVideo({required this.media});
  final HomeCampaignMediaData media;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      key: const ValueKey('campaign_video_viewport'),
      aspectRatio: AppMediaSpecs.campaignMediaAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AppVideo(
          url: media.videoUrl,
          poster: _PosterOrPlaceholder(posterUrl: media.posterUrl),
          fallback: const _MediaPlaceholder(),
          fit: BoxFit.contain,
          showControls: true,
        ),
      ),
    );
  }
}

class _PosterOrPlaceholder extends StatelessWidget {
  const _PosterOrPlaceholder({required this.posterUrl});
  final String posterUrl;
  @override
  Widget build(BuildContext context) => AppImage(
    source: posterUrl,
    fallbackType: AppImagePlaceholderType.offer,
    fit: BoxFit.contain,
  );
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();
  @override
  Widget build(BuildContext context) =>
      const AppImage(source: AppAssets.defaultOffer, fit: BoxFit.contain);
}
