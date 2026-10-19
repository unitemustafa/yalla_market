import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:ui' show FramePhase;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:yalla_market/core/network/api_endpoints.dart';
import 'package:yalla_market/main.dart' as application;
import 'performance_release_review.dart';

/// Release-only observer. It measures the real application shell, with external
/// Firebase services disabled by the isolated package flag in main.dart.
Future<void> main() async {
  if (!kReleaseMode || !const bool.fromEnvironment('PERFORMANCE_TEST_BUILD')) {
    throw StateError('Startup observer requires an isolated release package');
  }
  if (ApiEndpoints.rootBaseUrl != 'http://127.0.0.1:18081') {
    throw StateError('Startup observer requires the isolated loopback API');
  }
  final mainUs = developer.Timeline.now;
  final binding = WidgetsFlutterBinding.ensureInitialized();
  void emit(Map<String, Object?> values) {
    // ignore: avoid_print
    print(
      'PERF_STARTUP ${jsonEncode({...values, 'epoch_ms': DateTime.now().millisecondsSinceEpoch})}',
    );
  }

  emit({
    'event': 'dart_main',
    'clock_us': mainUs,
    'scope': 'isolated_staging_firebase_disabled',
    'observer_protocol': 'interactive_entry_raster_v2',
  });
  void firstFrame(List<FrameTiming> timings) {
    if (timings.isEmpty) return;
    final rasterEnd = timings.first.timestampInMicroseconds(
      FramePhase.rasterFinish,
    );
    emit({
      'event': 'first_frame',
      'dart_main_to_raster_ms': (rasterEnd - mainUs) / 1000,
      'raster_finish_us': rasterEnd,
      'clock_us': mainUs,
    });
    binding.removeTimingsCallback(firstFrame);
  }

  binding.addTimingsCallback(firstFrame);
  binding.addObserver(_ResumeProbe(binding, emit));
  var done = false;
  void ready(Duration _) {
    if (done) return;
    final screen = _interactiveEntry(binding);
    if (screen != null) {
      done = true;
      final visibleVsync = binding.currentSystemFrameTimeStamp.inMicroseconds;
      void rasterized(List<FrameTiming> timings) {
        final eligible = timings.where(
          (frame) =>
              frame.timestampInMicroseconds(FramePhase.vsyncStart) >=
              visibleVsync,
        );
        if (eligible.isEmpty) {
          return;
        }
        emit({
          'event': 'usable_content',
          'screen': screen,
          'dart_main_to_content_ms':
              (eligible.first.timestampInMicroseconds(FramePhase.rasterFinish) -
                  mainUs) /
              1000,
          'definition':
              'current entry route transition completed and rasterized; images may still load',
        });
        binding.removeTimingsCallback(rasterized);
      }

      binding.addTimingsCallback(rasterized);
      binding.scheduleFrame();
    } else {
      binding.addPostFrameCallback(ready);
    }
  }

  binding.addPostFrameCallback(ready);
  await application.main();
  // No fixture exists during cold/warm startup sampling. A later explicit
  // private-file push enables one functional release review in this package.
  unawaited(runRequestedReleaseReview(binding, emit));
}

String? _interactiveEntry(WidgetsBinding binding) {
  String? screen;
  void visit(Element element) {
    if (screen != null ||
        (element.widget is Offstage && (element.widget as Offstage).offstage)) {
      return;
    }
    final name = element.widget.runtimeType.toString();
    if (name == 'LoginView' || name == 'OnboardingView') {
      final route = ModalRoute.of(element);
      if ((route?.isCurrent ?? true) &&
          (route?.animation?.status ?? AnimationStatus.completed) ==
              AnimationStatus.completed) {
        screen = name;
        return;
      }
    }
    element.visitChildElements(visit);
  }

  binding.rootElement?.visitChildElements(visit);
  return screen;
}

class _ResumeProbe with WidgetsBindingObserver {
  _ResumeProbe(this.binding, this.emit);
  final WidgetsBinding binding;
  final void Function(Map<String, Object?>) emit;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final resumedUs = developer.Timeline.now;
    void timing(List<FrameTiming> timings) {
      final frames = timings.where(
        (frame) =>
            frame.timestampInMicroseconds(FramePhase.rasterFinish) >= resumedUs,
      );
      if (frames.isEmpty) return;
      final finish = frames.first.timestampInMicroseconds(
        FramePhase.rasterFinish,
      );
      emit({
        'event': 'resume_first_frame',
        'resume_to_raster_ms': (finish - resumedUs) / 1000,
      });
      final screen = _interactiveEntry(binding);
      if (screen != null) {
        emit({
          'event': 'resume_usable_content',
          'screen': screen,
          'resume_to_content_ms': (finish - resumedUs) / 1000,
        });
      }
      binding.removeTimingsCallback(timing);
    }

    binding.addTimingsCallback(timing);
  }
}
