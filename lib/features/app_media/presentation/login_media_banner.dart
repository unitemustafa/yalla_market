import 'package:flutter/material.dart';

import '../../../core/domain/media_focal_point.dart';
import '../../../core/presentation/media/app_video.dart';
import '../../../core/presentation/media/media_focal_point_alignment.dart';
import '../../../core/presentation/widgets/images/app_image.dart';

class LoginMediaBanner extends StatefulWidget {
  const LoginMediaBanner({
    super.key,
    required this.url,
    required this.posterUrl,
    required this.focus,
    required this.fallback,
    this.isLoading = false,
  });
  final String? url;
  final String? posterUrl;
  final MediaFocalPoint focus;
  final String fallback;
  final bool isLoading;

  @override
  State<LoginMediaBanner> createState() => _LoginMediaBannerState();
}

class _LoginMediaBannerState extends State<LoginMediaBanner> {
  @override
  Widget build(BuildContext context) {
    final loading = ColoredBox(color: Theme.of(context).colorScheme.surface);
    if (widget.isLoading) return loading;
    final alignment = widget.focus.alignment;
    final fallback = AppImage(
      source: widget.fallback,
      fit: BoxFit.cover,
      alignment: alignment,
      cacheHeight: 480,
    );
    final rawUrl = widget.url?.trim() ?? '';
    final isVideo =
        Uri.tryParse(rawUrl)?.path.toLowerCase().endsWith('.mp4') ?? false;
    if (!isVideo) {
      return AppImage(
        source: rawUrl,
        fallback: fallback,
        fit: BoxFit.cover,
        alignment: alignment,
        cacheHeight: 480,
      );
    }
    return AppVideo(
      url: rawUrl,
      alignment: alignment,
      loading: loading,
      fallback: fallback,
      poster: AppImage(
        source: widget.posterUrl,
        fallback: fallback,
        fit: BoxFit.cover,
        alignment: alignment,
        cacheHeight: 480,
      ),
    );
  }
}
