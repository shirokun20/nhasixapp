import 'package:equatable/equatable.dart';

import 'compatibility_status.dart';
import 'diagnostic_severity.dart';
import 'feature_kind.dart';
import 'feature_status.dart';
import 'validation_diagnostic.dart';

/// Aggregated compatibility report for a single source config.
///
/// Produced by the `kuron_generic` validator (Section 4) and consumed by
/// the app import flow, reader pre-flight checks, and download readiness
/// checks.
class ValidationReport extends Equatable {
  ValidationReport({
    required this.sourceId,
    required this.overallStatus,
    required this.featureStatuses,
    this.schemaVersion,
    this.engineVersion,
    this.minEngineVersion,
    this.diagnostics = const <ValidationDiagnostic>[],
    Set<String>? requiredPlugins,
    Set<String>? detectedPlugins,
    Set<String>? missingPlugins,
    DateTime? generatedAt,
    this.mode = ValidationMode.staticMode,
  })  : requiredPlugins =
            Set<String>.unmodifiable(requiredPlugins ?? const <String>{}),
        detectedPlugins =
            Set<String>.unmodifiable(detectedPlugins ?? const <String>{}),
        missingPlugins =
            Set<String>.unmodifiable(missingPlugins ?? const <String>{}),
        generatedAt = generatedAt ?? DateTime.now().toUtc();

  /// Source identifier from the config (e.g. `nhentai`, `mangadex`).
  final String sourceId;

  /// Overall status computed from [featureStatuses] and [diagnostics].
  /// See [computeOverallStatus] for the deterministic algorithm.
  final CompatibilityStatus overallStatus;

  /// Per-feature status. Features not present in this map are treated as
  /// [FeatureStatus.notDeclared] by consumers.
  final Map<FeatureKind, FeatureStatus> featureStatuses;

  /// Declared `schemaVersion` from the config, when present.
  final String? schemaVersion;

  /// Engine version of the runtime that produced this report.
  final String? engineVersion;

  /// Minimum engine version required by the config (`minEngineVersion`), when
  /// declared.
  final String? minEngineVersion;

  /// All diagnostics emitted during validation. Already secret-redacted.
  final List<ValidationDiagnostic> diagnostics;

  /// Plugin capability identifiers the config requires.
  final Set<String> requiredPlugins;

  /// Plugin capability identifiers that the host actually registered.
  final Set<String> detectedPlugins;

  /// Plugin capability identifiers that are required but missing.
  final Set<String> missingPlugins;

  /// When this report was generated, in UTC.
  final DateTime generatedAt;

  /// Validation mode used to produce this report.
  final ValidationMode mode;

  /// Returns the diagnostics restricted to a single feature.
  List<ValidationDiagnostic> diagnosticsFor(FeatureKind feature) {
    return diagnostics
        .where((ValidationDiagnostic d) => d.feature == feature)
        .toList(growable: false);
  }

  /// Returns all diagnostics matching [severity].
  List<ValidationDiagnostic> diagnosticsOf({
    required DiagnosticSeverity severity,
  }) {
    return diagnostics
        .where((ValidationDiagnostic d) => d.severity == severity)
        .toList(growable: false);
  }

  /// Returns true if any diagnostic of severity [DiagnosticSeverity.error]
  /// exists in this report.
  bool get hasErrors => diagnostics
      .any((ValidationDiagnostic d) => d.severity == DiagnosticSeverity.error);

  /// Returns true if any diagnostic of severity [DiagnosticSeverity.warning]
  /// exists in this report.
  bool get hasWarnings => diagnostics.any(
      (ValidationDiagnostic d) => d.severity == DiagnosticSeverity.warning);

  ValidationReport copyWith({
    String? sourceId,
    CompatibilityStatus? overallStatus,
    Map<FeatureKind, FeatureStatus>? featureStatuses,
    String? schemaVersion,
    String? engineVersion,
    String? minEngineVersion,
    List<ValidationDiagnostic>? diagnostics,
    Set<String>? requiredPlugins,
    Set<String>? detectedPlugins,
    Set<String>? missingPlugins,
    DateTime? generatedAt,
    ValidationMode? mode,
  }) {
    return ValidationReport(
      sourceId: sourceId ?? this.sourceId,
      overallStatus: overallStatus ?? this.overallStatus,
      featureStatuses: featureStatuses ?? this.featureStatuses,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      engineVersion: engineVersion ?? this.engineVersion,
      minEngineVersion: minEngineVersion ?? this.minEngineVersion,
      diagnostics: diagnostics ?? this.diagnostics,
      requiredPlugins: requiredPlugins ?? this.requiredPlugins,
      detectedPlugins: detectedPlugins ?? this.detectedPlugins,
      missingPlugins: missingPlugins ?? this.missingPlugins,
      generatedAt: generatedAt ?? this.generatedAt,
      mode: mode ?? this.mode,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'sourceId': sourceId,
        'overallStatus': overallStatus.name,
        'mode': mode.name,
        'schemaVersion': schemaVersion,
        'engineVersion': engineVersion,
        'minEngineVersion': minEngineVersion,
        'generatedAt': generatedAt.toIso8601String(),
        'featureStatuses': <String, String>{
          for (final MapEntry<FeatureKind, FeatureStatus> e
              in featureStatuses.entries)
            e.key.name: e.value.name,
        },
        'requiredPlugins': requiredPlugins.toList(growable: false),
        'detectedPlugins': detectedPlugins.toList(growable: false),
        'missingPlugins': missingPlugins.toList(growable: false),
        'diagnostics':
            diagnostics.map((ValidationDiagnostic d) => d.toJson()).toList(
                  growable: false,
                ),
      };

  /// Computes a deterministic [CompatibilityStatus] from per-feature
  /// statuses, diagnostics, and plugin gap.
  ///
  /// The required-feature set is provided by the caller (typically the
  /// validator that owns the config contract). Optional-feature failures
  /// degrade to [CompatibilityStatus.partiallyCompatible] rather than
  /// failing the source overall.
  static CompatibilityStatus computeOverallStatus({
    required Map<FeatureKind, FeatureStatus> featureStatuses,
    required Set<FeatureKind> requiredFeatures,
    required List<ValidationDiagnostic> diagnostics,
    Set<String> missingPlugins = const <String>{},
  }) {
    bool anyConfigError = diagnostics.any((ValidationDiagnostic d) =>
        d.severity == DiagnosticSeverity.error && d.code.startsWith('config'));

    bool anyBlocked = false;
    bool anyNeedsAuth = false;
    bool anyRequiresPlugin = missingPlugins.isNotEmpty;
    bool anyRequiredFailed = false;
    bool anyOptionalFailed = false;

    for (final FeatureKind feature in featureStatuses.keys) {
      final FeatureStatus status = featureStatuses[feature]!;
      final bool isRequired = requiredFeatures.contains(feature);
      switch (status) {
        case FeatureStatus.compatible:
        case FeatureStatus.inferred:
        case FeatureStatus.notDeclared:
        case FeatureStatus.unsupported:
          break;
        case FeatureStatus.partiallyCompatible:
          if (isRequired) {
            anyOptionalFailed = true;
          } else {
            anyOptionalFailed = true;
          }
          break;
        case FeatureStatus.configError:
          anyConfigError = true;
          if (isRequired) {
            anyRequiredFailed = true;
          } else {
            anyOptionalFailed = true;
          }
          break;
        case FeatureStatus.requiresPlugin:
          anyRequiresPlugin = true;
          if (isRequired) {
            anyRequiredFailed = true;
          } else {
            anyOptionalFailed = true;
          }
          break;
        case FeatureStatus.needsAuthSupport:
          anyNeedsAuth = true;
          if (isRequired) {
            anyRequiredFailed = true;
          } else {
            anyOptionalFailed = true;
          }
          break;
        case FeatureStatus.blockedBySiteProtection:
          anyBlocked = true;
          if (isRequired) {
            anyRequiredFailed = true;
          } else {
            anyOptionalFailed = true;
          }
          break;
      }
    }

    // Required-feature gaps win over optional gaps.
    if (anyRequiredFailed) {
      if (anyBlocked) return CompatibilityStatus.blockedBySiteProtection;
      if (anyNeedsAuth) return CompatibilityStatus.needsAuthSupport;
      if (anyRequiresPlugin) return CompatibilityStatus.needsEngineSupport;
      if (anyConfigError) return CompatibilityStatus.configError;
      return CompatibilityStatus.configError;
    }
    if (anyOptionalFailed) return CompatibilityStatus.partiallyCompatible;
    return CompatibilityStatus.compatible;
  }

  @override
  List<Object?> get props => <Object?>[
        sourceId,
        overallStatus,
        featureStatuses,
        schemaVersion,
        engineVersion,
        minEngineVersion,
        diagnostics,
        requiredPlugins,
        detectedPlugins,
        missingPlugins,
        mode,
        // generatedAt intentionally excluded from equality so reports with
        // identical content compare equal.
      ];
}

/// Mode the validator ran in.
enum ValidationMode {
  /// Static schema/structural validation only. No network. Default in CI.
  staticMode,

  /// Static + replay against stored fixtures (no network).
  fixture,

  /// Static + optional probe against the live site. Network required.
  live,
}
