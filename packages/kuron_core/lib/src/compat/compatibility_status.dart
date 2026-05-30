/// Overall compatibility status of a source config against the runtime.
///
/// See proposal `revamp-kuron-config-runtime` for status definitions.
enum CompatibilityStatus {
  /// All declared required features pass and at least one optional feature
  /// is also compatible (or no optional features are declared).
  compatible,

  /// Required core features pass but one or more optional features failed
  /// or are inferred only. The source may still be enabled; failed optional
  /// features must be disabled per-feature, not per-source.
  partiallyCompatible,

  /// The config itself is malformed or misses required fields.
  configError,

  /// One or more required primitives are not implemented by the current
  /// engine version.
  needsEngineSupport,

  /// One or more required features need authentication and the auth
  /// pipeline is missing or unconfigured.
  needsAuthSupport,

  /// The remote site cannot be reached without external bypass (Cloudflare,
  /// regional block, paywall, etc.).
  blockedBySiteProtection,
}

// ── Generator metadata (§11.2) ───────────────────────────────────────────────

/// All [CompatibilityStatus] value names as a compile-time constant list.
///
/// Config generators and tooling can use this list to validate that
/// generated output references valid status names, without depending on
/// runtime enum reflection.
const List<String> compatibilityStatusNames = <String>[
  'compatible',
  'partiallyCompatible',
  'configError',
  'needsEngineSupport',
  'needsAuthSupport',
  'blockedBySiteProtection',
];
