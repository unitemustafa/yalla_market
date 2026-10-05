import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:yalla_market/app/routing/app_route_observer.dart';
import 'package:yalla_market/core/presentation/media/app_video.dart';
import 'package:yalla_market/core/presentation/media/media_route_observer_scope.dart';
import 'package:yalla_market/core/domain/media_focal_point.dart';
import 'package:yalla_market/core/presentation/widgets/images/app_image.dart';
import 'package:yalla_market/features/app_media/presentation/login_media_banner.dart';

class _VideoPlatform extends VideoPlayerPlatform {
  late final events = StreamController<VideoEvent>.broadcast();
  final disposals = <int>[];
  var plays = 0;
  var pauses = 0;

  void initializeVideo() => events.add(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 5),
      size: const Size(320, 180),
    ),
  );
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;
  @override
  Future<void> dispose(int playerId) async {
    disposals.add(playerId);
  }

  @override
  Future<void> play(int playerId) async {
    plays++;
  }

  @override
  Future<void> pause(int playerId) async {
    pauses++;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();
}

const _surface = SizedBox(
  width: 200,
  height: 100,
  child: AppVideo(
    url: 'https://example.test/video.mp4',
    showControls: true,
    poster: ColoredBox(key: ValueKey('poster'), color: Colors.blue),
    fallback: ColoredBox(key: ValueKey('fallback'), color: Colors.black),
  ),
);

void main() {
  late _VideoPlatform platform;
  late VideoPlayerPlatform previous;
  setUp(() {
    previous = VideoPlayerPlatform.instance;
    platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
  });
  tearDown(() async {
    VideoPlayerPlatform.instance = previous;
    await platform.events.close();
  });

  testWidgets(
    'login video never flashes the old artwork during initialization',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 360,
            height: 240,
            child: LoginMediaBanner(
              url: 'https://example.test/login.mp4',
              posterUrl: 'https://example.test/old-poster.webp',
              focus: MediaFocalPoint.topCenter,
              fallback: 'old-login-artwork.webp',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AppImage), findsNothing);
      expect(find.byType(FittedBox), findsNothing);
      platform.initializeVideo();
      await tester.pump();
      await tester.pump();
      expect(find.byType(FittedBox), findsOneWidget);
      expect(find.byType(AppImage), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'custom loading changes to the normal error fallback on timeout',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 100,
            child: AppVideo(
              url: 'https://example.test/video.mp4',
              loading: ColoredBox(key: ValueKey('loading'), color: Colors.grey),
              poster: ColoredBox(key: ValueKey('poster'), color: Colors.blue),
              fallback: ColoredBox(
                key: ValueKey('fallback'),
                color: Colors.black,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('loading')), findsOneWidget);
      expect(find.byKey(const ValueKey('poster')), findsNothing);
      expect(find.byKey(const ValueKey('fallback')), findsNothing);
      await tester.pump(const Duration(seconds: 11));
      await tester.pump();
      expect(find.byKey(const ValueKey('loading')), findsNothing);
      expect(find.byKey(const ValueKey('poster')), findsOneWidget);
      expect(find.byKey(const ValueKey('fallback')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('initialization times out to the poster and disposes once', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _surface));
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(find.byKey(const ValueKey('poster')), findsOneWidget);
    expect(platform.plays, 0);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(platform.disposals, [1]);
    await tester.pumpWidget(const SizedBox());
    expect(platform.disposals, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initialization completed in background waits for foreground', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _surface));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    platform.initializeVideo();
    await tester.pump();
    await tester.pump();
    expect(platform.plays, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(platform.plays, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a user pause survives background and foreground transitions', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const MaterialApp(home: _surface));
    await tester.pump();
    platform.initializeVideo();
    await tester.pump();
    await tester.pump();
    expect(platform.plays, 1);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(platform.plays, 1);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a pushed route pauses playback and popping resumes it', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final observer = AppRouteObserver(() {});
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [observer],
        builder: (context, child) =>
            MediaRouteObserverScope(observer: observer, child: child!),
        home: const Scaffold(body: _surface),
      ),
    );
    await tester.pump();
    platform.initializeVideo();
    await tester.pump();
    await tester.pump();
    final before = platform.pauses;
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(platform.pauses, greaterThan(before));
    final playCount = platform.plays;
    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(platform.plays, greaterThan(playCount));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a late initialize after disposal cannot start playback', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _surface));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    platform.initializeVideo();
    await tester.pump(const Duration(seconds: 11));
    expect(platform.plays, 0);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(platform.disposals, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid video URLs keep the poster and local fallback visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 200,
          height: 100,
          child: AppVideo(
            url: 'not a URL',
            poster: ColoredBox(key: ValueKey('poster'), color: Colors.blue),
            fallback: ColoredBox(
              key: ValueKey('fallback'),
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('poster')), findsOneWidget);
    expect(find.byKey(const ValueKey('fallback')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
