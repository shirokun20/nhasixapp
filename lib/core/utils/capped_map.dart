import 'dart:collection';

/// A [Map] that automatically evicts the oldest entry (FIFO) when exceeding [maxCapacity].
class CappedMap<K, V> extends MapBase<K, V> {
  final int maxCapacity;
  final LinkedHashMap<K, V> _inner = LinkedHashMap<K, V>();

  CappedMap(this.maxCapacity);

  @override
  V? operator [](Object? key) => _inner[key];

  @override
  void operator []=(K key, V value) {
    if (_inner.containsKey(key)) {
      _inner.remove(key);
    } else if (_inner.length >= maxCapacity) {
      _inner.remove(_inner.keys.first);
    }
    _inner[key] = value;
  }

  @override
  void clear() => _inner.clear();

  @override
  Iterable<K> get keys => _inner.keys;

  @override
  V? remove(Object? key) => _inner.remove(key);
}
