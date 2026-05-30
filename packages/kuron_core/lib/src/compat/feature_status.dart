/// Per-feature compatibility status emitted by validation.
///
/// Distinguishes between explicitly declared vs inferred features, and
/// between configuration errors, engine/plugin gaps, auth gaps, and site
/// protection. Tolerates v1 configs that do not declare features explicitly.
enum FeatureStatus {
  /// Declared and compatible end-to-end.
  compatible,

  /// Declared and partially compatible (e.g. core paths work but sub-paths
  /// like comments-pagination or related-fallback do not).
  partiallyCompatible,

  /// Not declared in the config and not inferable from primitives.
  notDeclared,

  /// Not declared in the config but inferred to work from config primitives
  /// (e.g. presence of `scraper.urlPatterns.search`). Treat as compatible at
  /// runtime but surface as a config-quality warning.
  inferred,

  /// Requires a `kuron_special` plugin capability that the host did not
  /// register.
  requiresPlugin,

  /// The config block backing this feature is malformed.
  configError,

  /// Feature needs authentication and the auth pipeline is unavailable.
  needsAuthSupport,

  /// Live probe was blocked by site protection (Cloudflare, captcha, etc.).
  blockedBySiteProtection,

  /// Feature is declared as unsupported on this source.
  unsupported,
}

// ── Generator metadata (§11.2) ───────────────────────────────────────────────

/// All [FeatureStatus] value names as a compile-time constant list.
const List<String> featureStatusNames = <String>[
  'compatible',
  'partiallyCompatible',
  'notDeclared',
  'inferred',
  'requiresPlugin',
  'configError',
  'needsAuthSupport',
  'blockedBySiteProtection',
  'unsupported',
];
