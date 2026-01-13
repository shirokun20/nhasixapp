import 'content_source.dart';

/// Registry for managing available content sources.
///
/// This class allows registering, retrieving, and switching between
/// different content sources at runtime.
class ContentSourceRegistry {
  final Map<String, ContentSource> _sources = {};
  String? _currentSourceId;

  /// Register a content source
  void register(ContentSource source) {
    _sources[source.id] = source;
    // Set as current if it's the first one
    _currentSourceId ??= source.id;
  }

  /// Unregister a content source
  void unregister(String sourceId) {
    _sources.remove(sourceId);
    if (_currentSourceId == sourceId) {
      _currentSourceId = _sources.keys.isNotEmpty ? _sources.keys.first : null;
    }
  }

  /// Get a source by ID
  ContentSource? getSource(String sourceId) => _sources[sourceId];

  /// Get all registered sources
  List<ContentSource> get allSources => _sources.values.toList();

  /// Get all source IDs
  List<String> get sourceIds => _sources.keys.toList();

  /// Get current active source
  ContentSource? get currentSource =>
      _currentSourceId != null ? _sources[_currentSourceId] : null;

  /// Get current source ID
  String? get currentSourceId => _currentSourceId;

  /// Switch to a different source
  bool switchSource(String sourceId) {
    if (_sources.containsKey(sourceId)) {
      _currentSourceId = sourceId;
      return true;
    }
    return false;
  }

  /// Check if a source is registered
  bool hasSource(String sourceId) => _sources.containsKey(sourceId);

  /// Get number of registered sources
  int get sourceCount => _sources.length;

  /// Check if any sources are registered
  bool get isEmpty => _sources.isEmpty;

  /// Check if sources are registered
  bool get isNotEmpty => _sources.isNotEmpty;
}
