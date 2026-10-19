import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Host-only collector. The URI is read from an ignored driver log, never
/// echoed into reports. Snapshot bytes are streamed directly to disk.
Future<void> main(List<String> args) async {
  if (args.length != 2) {
    throw ArgumentError('Expected driver-log and output-directory');
  }
  final log = File(args[0]);
  final output = Directory(args[1]);
  await output.create(recursive: true);
  String? address;
  for (var attempt = 0; attempt < 240; attempt++) {
    if (await log.exists()) {
      final bytes = await log.readAsBytes();
      final text = bytes.length >= 2 && bytes[0] == 255 && bytes[1] == 254
          ? String.fromCharCodes([
              for (var i = 2; i + 1 < bytes.length; i += 2)
                bytes[i] | (bytes[i + 1] << 8),
            ])
          : utf8.decode(bytes, allowMalformed: true);
      address =
          RegExp(
            r'Connecting to Flutter application at (http://[^\s]+)',
          ).firstMatch(text)?.group(1) ??
          RegExp(
            r'Dart VM Service.*(http://127\.0\.0\.1:[^\s]+)',
          ).firstMatch(text)?.group(1);
      if (address != null) break;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  if (address == null) throw StateError('No local VM service in driver log');
  final uri = Uri.parse(address);
  if (uri.host != '127.0.0.1' && uri.host != 'localhost') {
    throw StateError('Only loopback VM services are permitted');
  }
  final ws = uri.replace(scheme: 'ws', path: '${uri.path}ws').toString();
  final service = await vmServiceConnectUri(ws);
  try {
    final vm = await service.getVM();
    final isolateId = vm.isolates!
        .firstWhere((isolate) => isolate.name == 'main')
        .id!;
    await service.streamListen('HeapSnapshot');
    Map<String, ClassHeapStats> baseline = {};
    for (final phase in ['baseline', 'after20', 'after_soak']) {
      var found = false;
      for (var i = 0; i < 2400; i++) {
        try {
          final state = await service.callServiceExtension(
            'ext.yalla.perf.memory',
            isolateId: isolateId,
          );
          if (state.json?['phase'] == phase) {
            found = true;
            break;
          }
        } on RPCError {
          /* The test may still be mounting. */
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (!found) {
        throw StateError('Memory checkpoint timed out: $phase');
      }
      final profile = await service.getAllocationProfile(isolateId, gc: true);
      await File(
        '${output.path}/$phase.allocations.json',
      ).writeAsString(jsonEncode(profile.toJson()));
      final sink = File('${output.path}/$phase.heapsnapshot').openWrite();
      final done = Completer<void>();
      final subscription = service.onHeapSnapshotEvent.listen((event) {
        if (event.isolate?.id != isolateId) return;
        final bytes = event.data;
        if (bytes != null) {
          sink.add(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
        }
        if (event.last == true && !done.isCompleted) done.complete();
      });
      try {
        await service.requestHeapSnapshot(isolateId);
        await done.future.timeout(const Duration(minutes: 2));
      } finally {
        await subscription.cancel();
        await sink.close();
      }
      final members = {
        for (final member in profile.members ?? <ClassHeapStats>[])
          member.classRef!.id!: member,
      };
      if (phase == 'baseline') {
        baseline = members;
      } else {
        final growth = <Map<String, Object?>>[];
        for (final entry in members.entries) {
          final name = entry.value.classRef?.name ?? '';
          final delta =
              (entry.value.instancesCurrent ?? 0) -
              (baseline[entry.key]?.instancesCurrent ?? 0);
          if (delta <= 0 ||
              !RegExp(
                r'Cubit|Controller|State|Timer|Subscription',
              ).hasMatch(name)) {
            continue;
          }
          final record = <String, Object?>{
            'class': name,
            'instance_delta': delta,
          };
          try {
            final instances = await service.getInstances(
              isolateId,
              entry.key,
              1,
            );
            if (instances.instances?.isNotEmpty ?? false) {
              final path = await service.getRetainingPath(
                isolateId,
                instances.instances!.first.id!,
                100,
              );
              record['retaining_path'] = path.toJson();
            }
          } on RPCError {
            record['retaining_path'] = 'object_collected_or_unavailable';
          }
          growth.add(record);
          if (growth.length >= 20) break;
        }
        await File('${output.path}/$phase.growth.json').writeAsString(
          jsonEncode({
            'diagnosis': 'Growth alone is not proof of a leak',
            'classes': growth,
          }),
        );
      }
      // ignore: avoid_print
      print('Saved allocation profile and heap snapshot: $phase');
      await service.callServiceExtension(
        'ext.yalla.perf.memory',
        isolateId: isolateId,
        args: {'continue': phase},
      );
    }
  } finally {
    await service.dispose();
  }
}
