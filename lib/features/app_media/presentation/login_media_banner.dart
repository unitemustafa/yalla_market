import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LoginMediaBanner extends StatefulWidget {
  const LoginMediaBanner({
    super.key,
    required this.url,
    required this.fallback,
  });
  final String? url;
  final String fallback;

  @override
  State<LoginMediaBanner> createState() => _LoginMediaBannerState();
}

class _LoginMediaBannerState extends State<LoginMediaBanner>
    with WidgetsBindingObserver {
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadVideo();
  }

  @override
  void didUpdateWidget(covariant LoginMediaBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _video?.dispose();
      _video = null;
      _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    final url = widget.url;
    if (url == null || !Uri.parse(url).path.toLowerCase().endsWith('.mp4')) {
      return;
    }
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = controller;
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(true);
      await controller.play();
      if (mounted && identical(_video, controller)) setState(() {});
    } catch (_) {
      if (mounted && identical(_video, controller)) setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _video?.play();
    } else {
      _video?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    final video = _video;
    if (video?.value.isInitialized == true && video?.value.hasError == false) {
      return FittedBox(
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: video!.value.size.width,
          height: video.value.size.height,
          child: VideoPlayer(video),
        ),
      );
    }
    if (url != null && !Uri.parse(url).path.toLowerCase().endsWith('.mp4')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, _, _) => Image.asset(
          widget.fallback,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      );
    }
    return Image.asset(
      widget.fallback,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      cacheHeight: 480,
    );
  }
}
