/// Memoizes pure calculations without retaining an unbounded input history.
class BoundedMemoizer<K, V extends Object> {
  BoundedMemoizer({required this.capacity}) : assert(capacity > 0);

  final int capacity;
  final _values = <K, V>{};

  V? lookup(K key) {
    final existing = _values.remove(key);
    if (existing != null) _values[key] = existing;
    return existing;
  }

  void store(K key, V value) {
    _values.remove(key);
    if (_values.length >= capacity) _values.remove(_values.keys.first);
    _values[key] = value;
  }

  void clear() => _values.clear();

  V resolve(K key, V Function() compute, {bool cache = true}) {
    if (!cache) return compute();
    final existing = lookup(key);
    if (existing != null) return existing;
    // A failed calculation must not evict a previously valid result.
    final value = compute();
    store(key, value);
    return value;
  }
}
