import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'media_route_observer_scope.dart';

/// A bounded network-video surface with a poster and a local fallback.
///
/// The player is deliberately best-effort: media must never block a login or
/// campaign UI while a connection is slow or a device cannot decode a file.
class AppVideo extends StatefulWidget {
  const AppVideo({
    super.key,
    required this.url,
    required this.poster,
    required this.fallback,
    this.loading,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.autoplay = true,
    this.looping = true,
    this.muted = true,
    this.showControls = false,
  });

  final String? url;
  final Widget poster;
  final Widget fallback;
  final Widget? loading;
  final AlignmentGeometry alignment;
  final BoxFit fit;
  final bool autoplay;
  final bool looping;
  final bool muted;
  final bool showControls;

  @override
  State<AppVideo> createState() => _AppVideoState();
}

class _AppVideoState extends State<AppVideo>
    with WidgetsBindingObserver, RouteAware {
  static const _initializationTimeout = Duration(seconds: 10);

  VideoPlayerController? _controller;
  final _disposedControllers = HashSet<VideoPlayerController>.identity();
  var _generation = 0;
  var _failed = false;
  var _manualPause = false;
  var _pausedForLifecycle = false;
  var _pausedForRoute = false;
  var _resumeRequested = false;
  RouteObserver<ModalRoute<dynamic>>? _routeObserver;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pausedForLifecycle = _isBackground(WidgetsBinding.instance.lifecycleState);
    _replaceVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer = MediaRouteObserverScope.maybeOf(context);
    final route = ModalRoute.of(context);
    if (identical(observer, _routeObserver) && identical(route, _route)) {
      return;
    }
    _routeObserver?.unsubscribe(this);
    _routeObserver = observer;
    _route = route;
    if (observer != null && route != null) {
      observer.subscribe(this, route);
      _pausedForRoute = !route.isCurrent;
    }
  }

  @override
  void didUpdateWidget(covariant AppVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _replaceVideo();
  }

  void _replaceVideo() {
    final previous = _controller;
    _generation++;
    _controller = null;
    _failed = false;
    _manualPause = false;
    _resumeRequested = false;
    if (previous != null) _disposeController(previous);
    _initialize(_generation);
  }

  Future<void> _initialize(int generation) async {
    final rawUrl = widget.url?.trim() ?? '';
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      _markFailed(generation);
      return;
    }

    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    controller.addListener(() => _onControllerChanged(controller, generation));
    try {
      await controller.initialize().timeout(_initializationTimeout);
      if (!_isCurrent(controller, generation)) {
        return _disposeController(controller);
      }
      await controller.setVolume(widget.muted ? 0 : 1);
      if (!_isCurrent(controller, generation)) return;
      await controller.setLooping(widget.looping);
      if (!_isCurrent(controller, generation)) return;
      await _playWhenVisible(controller, generation);
      if (_isCurrent(controller, generation)) setState(() {});
    } on Object {
      _markFailed(generation, controller: controller);
    }
  }

  bool _isCurrent(VideoPlayerController controller, int generation) =>
      mounted &&
      generation == _generation &&
      identical(_controller, controller);

  bool get _isPaused => _pausedForLifecycle || _pausedForRoute;

  static bool _isBackground(AppLifecycleState? state) =>
      state != null && state != AppLifecycleState.resumed;

  Future<void> _playWhenVisible(
    VideoPlayerController controller,
    int generation,
  ) async {
    if (!_isCurrent(controller, generation) ||
        _isPaused ||
        _manualPause ||
        (!widget.autoplay && !_resumeRequested)) {
      return;
    }
    try {
      await controller.play();
      if (_isCurrent(controller, generation)) _resumeRequested = false;
    } on Object {
      _markFailed(generation, controller: controller);
    }
  }

  void _onControllerChanged(VideoPlayerController controller, int generation) {
    if (!_isCurrent(controller, generation)) return;
    if (controller.value.hasError) {
      _markFailed(generation, controller: controller);
    }
  }

  void _markFailed(int generation, {VideoPlayerController? controller}) {
    if (!mounted || generation != _generation) return;
    if (controller != null && !identical(_controller, controller)) return;
    if (_failed) return;
    _failed = true;
    final failedController = _controller;
    _controller = null;
    if (failedController != null) _disposeController(failedController);
    if (mounted) setState(() {});
  }

  void _disposeController(VideoPlayerController controller) {
    if (_disposedControllers.add(controller)) {
      unawaited(controller.dispose().catchError((Object _) {}));
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || _failed || !controller.value.isInitialized) {
      return;
    }
    try {
      if (controller.value.isPlaying) {
        _manualPause = true;
        await controller.pause();
      } else {
        _manualPause = false;
        await controller.play();
      }
      if (_isCurrent(controller, _generation)) setState(() {});
    } on Object {
      _markFailed(_generation, controller: controller);
    }
  }

  Future<void> _toggleMute() async {
    final controller = _controller;
    if (controller == null || _failed || !controller.value.isInitialized) {
      return;
    }
    try {
      await controller.setVolume(controller.value.volume == 0 ? 1 : 0);
      if (_isCurrent(controller, _generation)) setState(() {});
    } on Object {
      _markFailed(_generation, controller: controller);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _pausedForLifecycle = _isBackground(state);
    final controller = _controller;
    if (controller == null || _failed || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_playWhenVisible(controller, _generation));
      return;
    }
    unawaited(_pauseForInterruption(controller));
  }

  Future<void> _pauseForInterruption(VideoPlayerController controller) async {
    try {
      if (controller.value.isPlaying) _resumeRequested = true;
      await controller.pause();
      if (_isCurrent(controller, _generation)) setState(() {});
    } on Object {
      _markFailed(_generation, controller: controller);
    }
  }

  void _pauseForRouteChange() {
    _pausedForRoute = true;
    final controller = _controller;
    if (controller != null && !_failed && controller.value.isInitialized) {
      unawaited(_pauseForInterruption(controller));
    }
  }

  void _resumeForRouteChange() {
    _pausedForRoute = false;
    final controller = _controller;
    if (controller != null && !_failed && controller.value.isInitialized) {
      unawaited(_playWhenVisible(controller, _generation));
    }
  }

  @override
  void didPushNext() => _pauseForRouteChange();

  @override
  void didPopNext() => _resumeForRouteChange();

  @override
  void didPop() => _pauseForRouteChange();

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    _routeObserver = null;
    _route = null;
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    _controller = null;
    if (controller != null) _disposeController(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = !_failed && controller?.value.isInitialized == true;
    if (!isReady) {
      if (!_failed && widget.loading != null) return widget.loading!;
      // The poster is allowed to fail independently, so the bundled fallback
      // stays behind it during both initialization and playback failures.
      return Stack(
        fit: StackFit.expand,
        children: [widget.fallback, widget.poster],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: widget.fit,
          alignment: widget.alignment,
          child: SizedBox(
            width: controller!.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        if (widget.showControls)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filled(
                    tooltip: controller.value.isPlaying
                        ? 'إيقاف الفيديو'
                        : 'تشغيل الفيديو',
                    onPressed: _togglePlayback,
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: controller.value.volume == 0
                        ? 'تشغيل الصوت'
                        : 'كتم الصوت',
                    onPressed: _toggleMute,
                    icon: Icon(
                      controller.value.volume == 0
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
