import 'content_source.dart';

/// Factory interface for creating [ContentSource] instances from config.
///
/// Each provider package registers a factory implementation that the
/// [SourceLoader] uses to instantiate sources based on loaded config.
///
/// ## Example
/// ```dart
/// @injectable
/// class NhentaiSourceFactory implements SourceFactory {
///   @override
///   String get sourceId => 'nhentai';
///
///   @override
///   ContentSource create(Map<String, dynamic> config) {
///     return NhentaiSource(config: config);
///   }
/// }
/// ```
abstract interface class SourceFactory {
  /// The source ID this factory handles (e.g., 'nhentai', 'mangadex')
  String get sourceId;

  /// Create a [ContentSource] instance from the given config map.
  ///
  /// [config] is the parsed JSON from `{sourceId}-config.json`.
  ContentSource create(Map<String, dynamic> config);
}
