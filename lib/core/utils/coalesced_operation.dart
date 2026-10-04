/// Joins callers to an active operation instead of returning early. Resetting
/// detaches an old session's operation; it does not cancel the underlying I/O.
class CoalescedOperation {
  Future<void>? _pending;

  bool get isRunning => _pending != null;

  Future<void> run(Future<void> Function() operation) {
    final active = _pending;
    if (active != null) return active;
    late final Future<void> pending;
    pending = Future<void>.sync(operation).whenComplete(() {
      if (identical(_pending, pending)) _pending = null;
    });
    _pending = pending;
    return pending;
  }

  void reset() => _pending = null;
}
