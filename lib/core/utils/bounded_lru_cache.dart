import 'dart:collection';

/// A small bounded least-recently-used cache for in-memory lookup results.
class BoundedLruCache<K extends Object, V extends Object> {
  /// Creates an LRU cache that stores at most [capacity] entries.
  BoundedLruCache({required this.capacity});

  /// Maximum number of entries retained by this cache.
  final int capacity;

  final LinkedHashMap<K, V> _entries = LinkedHashMap<K, V>();

  /// Current number of cached entries.
  int get length => _entries.length;

  /// Returns the cached value for [key], marking it recently used.
  V? get(K key) {
    if (!_entries.containsKey(key)) {
      return null;
    }

    final value = _entries.remove(key);
    if (value == null) {
      return null;
    }

    _entries[key] = value;
    return value;
  }

  /// Stores [value] for [key], evicting old entries when over capacity.
  void set(K key, V value) {
    if (capacity <= 0) {
      return;
    }

    _entries.remove(key);
    _entries[key] = value;

    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Removes all cached entries.
  void clear() => _entries.clear();
}
