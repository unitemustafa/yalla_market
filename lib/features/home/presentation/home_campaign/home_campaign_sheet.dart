import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_media_specs.dart';
import '../../domain/entities/home_campaign_data.dart';

enum HomeCampaignSheetResult { dismissed, acted }

Future<HomeCampaignSheetResult?> showHomeCampaignSheet(
  BuildContext context,
  HomeCampaignData campaign,
) {
  return showModalBottomSheet<HomeCampaignSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    builder: (_) => _HomeCampaignSheet(campaign: campaign),
  );
}

class _HomeCampaignSheet extends StatelessWidget {
  const _HomeCampaignSheet({required this.campaign});

  final HomeCampaignData campaign;

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
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * _heightFactor(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: sheetBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 4),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: sheetTextColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
                child: campaign.sheet.template == 'split'
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _CampaignMedia(campaign.media)),
                          const SizedBox(width: 14),
                          Expanded(child: content),
                        ],
                      )
                    : Column(
                        children: [
                          if (campaign.media.type != 'none') ...[
                            _CampaignMedia(campaign.media),
                            const SizedBox(height: 18),
                          ],
                          content,
                        ],
                      ),
              ),
            ),
            if (campaign.action.hasButton)
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Color(sheet.buttonBackgroundColorValue),
                      foregroundColor: Color(sheet.buttonTextColorValue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.pop(context, HomeCampaignSheetResult.acted),
                    child: Text(
                      campaign.action.label,
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
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
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
  const _CampaignMedia(this.media);
  final HomeCampaignMediaData media;

  @override
  Widget build(BuildContext context) {
    if (media.type == 'video') {
      return _CampaignVideo(media: media);
    }
    if (media.type != 'image' || media.imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }
    return AspectRatio(
      key: const ValueKey('campaign_image_viewport'),
      aspectRatio: AppMediaSpecs.campaignMediaAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: media.imageUrl,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (_, _) => const _MediaPlaceholder(),
          errorWidget: (_, _, _) => const _MediaPlaceholder(),
        ),
      ),
    );
  }
}

class _CampaignVideo extends StatefulWidget {
  const _CampaignVideo({required this.media});
  final HomeCampaignMediaData media;

  @override
  State<_CampaignVideo> createState() => _CampaignVideoState();
}

class _CampaignVideoState extends State<_CampaignVideo>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    final uri = Uri.tryParse(widget.media.videoUrl);
    if (uri == null || !uri.hasScheme) {
      setState(() => _error = StateError('Invalid video URL'));
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    controller.addListener(_handleVideoError);
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _handleVideoError() {
    final controller = _controller;
    if (!mounted || _error != null || controller?.value.hasError != true) {
      return;
    }
    setState(() {
      _error = StateError(
        controller?.value.errorDescription ?? 'Video playback failed',
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _controller?.pause();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller?.value.isInitialized == true && _error == null;
    return AspectRatio(
      key: const ValueKey('campaign_video_viewport'),
      aspectRatio: AppMediaSpecs.campaignMediaAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller!.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            else
              _PosterOrPlaceholder(posterUrl: widget.media.posterUrl),
            if (ready)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: IconButton.filled(
                    onPressed: () async {
                      final activeController = _controller;
                      if (activeController == null) return;
                      activeController.value.isPlaying
                          ? await activeController.pause()
                          : await activeController.play();
                      if (mounted) setState(() {});
                    },
                    icon: Icon(
                      controller!.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
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

class _PosterOrPlaceholder extends StatelessWidget {
  const _PosterOrPlaceholder({required this.posterUrl});
  final String posterUrl;
  @override
  Widget build(BuildContext context) => posterUrl.isEmpty
      ? const _MediaPlaceholder()
      : CachedNetworkImage(
          imageUrl: posterUrl,
          fit: BoxFit.cover,
          placeholder: (_, _) => const _MediaPlaceholder(),
          errorWidget: (_, _, _) => const _MediaPlaceholder(),
        );
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black.withValues(alpha: 0.06),
    alignment: Alignment.center,
    child: const CircularProgressIndicator.adaptive(),
  );
}
