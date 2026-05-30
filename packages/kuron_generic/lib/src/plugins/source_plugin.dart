/// Source runtime plugin interfaces (Section 6.1).
///
/// Defines the interfaces that `kuron_special` plugins must implement.
/// `kuron_generic` depends only on these interfaces — never on concrete
/// plugin implementations. The host app injects plugins via [SourcePluginRegistry].
///
/// ## Plugin lifecycle
///
/// A plugin is selected by matching [SourcePlugin.capability] against the
/// [SourceCapabilityDeclaration.allRequiredPlugins] set produced by the
/// validator. If a required plugin is missing, the feature status for the
/// relevant [FeatureKind] is [FeatureStatus.requiresPlugin].
library;

import 'package:kuron_core/kuron_core.dart';

import '../config/source_config_parser.dart';
import '../pipeline/page_resolution_pipeline.dart';

// ── Base interface ────────────────────────────────────────────────────────────

/// Base interface for all source runtime plugins.
///
/// Every plugin must declare a [capability] string that matches one of the
/// constants defined in [PluginCapability] (kuron_core).
abstract interface class SourcePlugin {
  /// Capability identifier (e.g. `plugin.ehentai.pageTokenFetch`).
  String get capability;
}

// ── Auth / session plugin ─────────────────────────────────────────────────────

/// Plugin that handles session setup (login, cookie injection, Turnstile).
abstract interface class SourceAuthPlugin implements SourcePlugin {
  /// Prepare auth session for [sourceId].
  ///
  /// Called before the first request when the source requires auth.
  /// Implementations may show a WebView, fetch a nonce, or refresh cookies.
  Future<SourceAuthResult> prepareSession(
    String sourceId,
    Map<String, Object?> rawConfig,
  );
}

/// Result of a [SourceAuthPlugin.prepareSession] call.
class SourceAuthResult {
  const SourceAuthResult({
    required this.success,
    this.headers = const <String, String>{},
    this.cookies = const <String, String>{},
    this.diagnostics = const <ValidationDiagnostic>[],
  });

  final bool success;
  final Map<String, String> headers;
  final Map<String, String> cookies;
  final List<ValidationDiagnostic> diagnostics;
}

// ── Image URL transform plugin ────────────────────────────────────────────────

/// Plugin that transforms raw/encrypted image URLs into final download URLs.
///
/// Used for HentaiNexus (XOR/RC4 decryption), EHentai (page-token fetch),
/// and CDN regex rewriting.
abstract interface class ImageUrlTransformPlugin implements SourcePlugin {
  /// Transform a list of raw image URLs (possibly encrypted or relative) into
  /// final direct download URLs.
  ///
  /// Called once per chapter after the adapter has collected raw URLs.
  Future<List<String>> transformImageUrls({
    required List<String> rawUrls,
    required Map<String, Object?> rawConfig,
    required Map<String, String> sessionHeaders,
  });
}

// ── Page resolution plugin ────────────────────────────────────────────────────

/// Plugin that performs special page resolution that cannot be expressed
/// as a primitive (e.g. Hitomi nozomi binary protocol).
abstract interface class PageResolutionPlugin implements SourcePlugin {
  /// Resolve chapter image URLs using a plugin-specific protocol.
  ///
  /// Returns a [PageResolutionInput] ready for [PageResolutionPipeline.resolve].
  Future<PageResolutionInput?> resolveChapterPages({
    required String sourceId,
    required String contentId,
    required String? chapterId,
    required Map<String, Object?> rawConfig,
    required Map<String, String> sessionHeaders,
  });
}

// ── Header generation plugin ──────────────────────────────────────────────────

/// Plugin that generates request headers dynamically (e.g. WordPress nonce).
abstract interface class HeaderGeneratorPlugin implements SourcePlugin {
  /// Generate a set of per-request headers for [url].
  Map<String, String> generateHeaders({
    required String url,
    required Map<String, Object?> rawConfig,
    Map<String, String> existingHeaders = const <String, String>{},
  });
}

// ── Plugin registry (6.2) ─────────────────────────────────────────────────────

/// Registry that lets apps inject plugins without making `kuron_generic`
/// depend on `kuron_special`.
///
/// Usage (in app DI setup):
/// ```dart
/// SourcePluginRegistry.instance
///   ..register(EHentaiPageTokenPlugin())
///   ..register(HitomiNozomiPlugin())
///   ..register(CloudflareWebViewPlugin());
/// ```
class SourcePluginRegistry {
  SourcePluginRegistry._();

  static final SourcePluginRegistry instance = SourcePluginRegistry._();

  final Map<String, SourcePlugin> _plugins = <String, SourcePlugin>{};

  /// Register a plugin. Overwrites any previously registered plugin with the
  /// same [SourcePlugin.capability].
  SourcePluginRegistry register(SourcePlugin plugin) {
    _plugins[plugin.capability] = plugin;
    return this;
  }

  /// Remove a plugin by [capability].
  void unregister(String capability) {
    _plugins.remove(capability);
  }

  /// Returns true if a plugin with [capability] is registered.
  bool has(String capability) => _plugins.containsKey(capability);

  /// Returns the registered plugin for [capability], or null.
  SourcePlugin? get(String capability) => _plugins[capability];

  /// Returns a typed plugin for [capability], or null if absent or wrong type.
  T? getAs<T extends SourcePlugin>(String capability) {
    final SourcePlugin? p = _plugins[capability];
    return p is T ? p : null;
  }

  /// All registered capability identifiers.
  Set<String> get registeredCapabilities => _plugins.keys.toSet();

  /// Build a [SourceConfigParser] that uses this registry's plugins.
  ///
  /// The returned parser will report detected plugins from the registry
  /// and compute accurate [FeatureStatus.requiresPlugin] / compatible statuses.
  SourceConfigParser toParser({String engineVersion = '2.0.0'}) {
    return SourceConfigParser(
      engineVersion: engineVersion,
      registeredPlugins: registeredCapabilities,
    );
  }

  /// Produce a [PluginCapabilityReport] for a [SourceCapabilityDeclaration].
  PluginCapabilityReport reportFor(SourceCapabilityDeclaration declaration) {
    final Set<String> required = declaration.allRequiredPlugins;
    final Set<String> detected = required.where((String c) => has(c)).toSet();
    final Set<String> missing = required.where((String c) => !has(c)).toSet();
    return PluginCapabilityReport(
      required: required,
      detected: detected,
      missing: missing,
    );
  }

  /// Reset all registered plugins (useful for tests).
  void reset() => _plugins.clear();
}

/// Summary of plugin capability coverage for a source.
class PluginCapabilityReport {
  const PluginCapabilityReport({
    required this.required,
    required this.detected,
    required this.missing,
  });

  final Set<String> required;
  final Set<String> detected;
  final Set<String> missing;

  bool get isComplete => missing.isEmpty;

  @override
  String toString() => 'PluginCapabilityReport(required=${required.length}, '
      'detected=${detected.length}, missing=${missing.length})';
}
