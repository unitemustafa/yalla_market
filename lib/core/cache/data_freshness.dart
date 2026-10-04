/// Tracks successful network syncs independently from cached/local data.
class DataFreshness {
  DataFreshness({
    this.maxAge = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration maxAge;
  final DateTime Function() _now;
  DateTime? _lastNetworkSuccessAt;
  int _revision = 0;

  DateTime? get lastNetworkSuccessAt => _lastNetworkSuccessAt;
  int get revision => _revision;

  bool get isStale {
    final lastSync = _lastNetworkSuccessAt;
    if (lastSync == null) return true;
    final age = _now().toUtc().difference(lastSync);
    return age.isNegative || age >= maxAge;
  }

  void markNetworkSuccess({int? revision}) {
    if (revision == null || revision == _revision) {
      _lastNetworkSuccessAt = _now().toUtc();
    }
  }

  void invalidate() {
    _revision++;
    _lastNetworkSuccessAt = null;
  }
}
