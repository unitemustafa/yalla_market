import 'dart:developer';
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/performance/customer_audit_scenarios.dart';
import 'core/customer_image_audit.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;

  testWidgets('customer interactions profile', (tester) async {
    expect(kProfileMode, isTrue);
    expect(const bool.fromEnvironment('PERFORMANCE_TEST_BUILD'), isTrue);
    final refreshHz = double.parse(
      const String.fromEnvironment('PERF_REFRESH_HZ', defaultValue: '60'),
    );
    final timings = <FrameTiming>[];
    final windows = <({String name, int start, int end})>[];
    final reports = <String, List<Object?>>{};
    binding.reportData = {
      'completed': false,
      'refresh_hz': refreshHz,
      'frame_budget_us': (1000000 / refreshHz).round(),
      'scenarios': reports,
    };
    void receive(List<FrameTiming> frames) => timings.addAll(frames);
    AuditMeasure collect(String prefix) => (name, action, {prepare}) async {
      for (var i = 0; i <= 5; i++) {
        await prepare?.call(i);
        final start = Timeline.now;
        await action(i);
        final end = Timeline.now;
        if (i > 0) windows.add((name: '$prefix$name', start: start, end: end));
      }
    };
    binding.addTimingsCallback(receive);
    try {
      await CustomerAuditScenarios(
        tester,
        collect('standard/'),
        large: false,
      ).run();
      await CustomerAuditScenarios(
        tester,
        collect('large/'),
        large: true,
      ).run();
      await runCustomerImageAudit(tester, collect('images/'));
      // The engine returns frame timings in batches. Timestamp windows keep
      // fixture setup and warm-ups out without instrumenting the widgets.
      await Future<void>.delayed(const Duration(seconds: 2));
    } finally {
      binding.removeTimingsCallback(receive);
    }
    expect(timings, isNotEmpty);
    for (final window in windows) {
      final frames = timings.where((frame) {
        final start = frame.timestampInMicroseconds(FramePhase.vsyncStart);
        return start >= window.start && start < window.end;
      });
      reports.putIfAbsent(window.name, () => []).add({
        'elapsed_us': window.end - window.start,
        'frames': [
          for (final frame in frames)
            [
              frame.buildDuration.inMicroseconds,
              frame.rasterDuration.inMicroseconds,
            ],
        ],
      });
    }
    expect(reports.values.every((runs) => runs.length == 5), isTrue);
    for (final name in ['standard/home_open', 'large/home_open']) {
      final homeOpen = reports[name]!.cast<Map<String, Object?>>();
      expect(
        homeOpen.every((run) => (run['frames']! as List).isNotEmpty),
        isTrue,
        reason: name,
      );
    }
    binding.reportData!['completed'] = true;
  });
}
