/// Report writers: JSON and Markdown output for [ValidationReport].
///
/// Used by the CLI validator and by the test harness.
library;

import 'dart:convert';

import 'package:kuron_core/kuron_core.dart';

// ── JSON report (4.5) ────────────────────────────────────────────────────────

/// Serialize a [ValidationReport] to pretty-printed JSON.
String reportToJson(ValidationReport report) {
  return const JsonEncoder.withIndent('  ').convert(_reportToMap(report));
}

Map<String, Object?> _reportToMap(ValidationReport report) {
  return <String, Object?>{
    'sourceId': report.sourceId,
    'overallStatus': report.overallStatus.name,
    'engineVersion': report.engineVersion,
    if (report.schemaVersion != null) 'schemaVersion': report.schemaVersion,
    if (report.minEngineVersion != null)
      'minEngineVersion': report.minEngineVersion,
    'mode': report.mode.name,
    'generatedAt': report.generatedAt.toIso8601String(),
    'featureStatuses': report.featureStatuses.map(
      (FeatureKind k, FeatureStatus v) =>
          MapEntry<String, String>(k.name, v.name),
    ),
    if (report.requiredPlugins.isNotEmpty)
      'requiredPlugins': report.requiredPlugins.toList(growable: false)..sort(),
    if (report.detectedPlugins.isNotEmpty)
      'detectedPlugins': report.detectedPlugins.toList(growable: false)..sort(),
    if (report.missingPlugins.isNotEmpty)
      'missingPlugins': report.missingPlugins.toList(growable: false)..sort(),
    'diagnostics': report.diagnostics
        .map((ValidationDiagnostic d) => <String, Object?>{
              'severity': d.severity.name,
              'code': d.code,
              'message': d.message,
              if (d.feature != null) 'feature': d.feature!.name,
              if (d.path != null) 'path': d.path,
              if (d.context.isNotEmpty) 'context': d.context,
            })
        .toList(growable: false),
  };
}

// ── Markdown report (4.5) ────────────────────────────────────────────────────

/// Serialize a [ValidationReport] to a Markdown document.
String reportToMarkdown(ValidationReport report) {
  final StringBuffer sb = StringBuffer();
  final String statusBadge = _statusBadge(report.overallStatus);
  sb
    ..writeln('# Config Validation Report — `${report.sourceId}`')
    ..writeln()
    ..writeln('| Field | Value |')
    ..writeln('|---|---|')
    ..writeln('| Status | $statusBadge |')
    ..writeln('| Engine | `${report.engineVersion}` |');
  if (report.schemaVersion != null) {
    sb.writeln('| Schema | `${report.schemaVersion}` |');
  }
  sb
    ..writeln('| Mode | `${report.mode.name}` |')
    ..writeln('| Generated | `${report.generatedAt.toIso8601String()}` |')
    ..writeln();

  // Feature table.
  sb
    ..writeln('## Feature Status')
    ..writeln()
    ..writeln('| Feature | Status |')
    ..writeln('|---|---|');
  for (final MapEntry<FeatureKind, FeatureStatus> e
      in report.featureStatuses.entries) {
    sb.writeln('| `${e.key.name}` | ${_featureBadge(e.value)} |');
  }
  sb.writeln();

  // Plugin summary.
  if (report.requiredPlugins.isNotEmpty) {
    sb.writeln('## Plugins');
    sb.writeln();
    final List<String> sorted = report.requiredPlugins.toList(growable: false)
      ..sort();
    for (final String p in sorted) {
      final bool ok = report.detectedPlugins.contains(p);
      sb.writeln('- ${ok ? '✅' : '❌'} `$p`');
    }
    sb.writeln();
  }

  // Diagnostics.
  final List<ValidationDiagnostic> errors = report.diagnostics
      .where((ValidationDiagnostic d) => d.severity == DiagnosticSeverity.error)
      .toList(growable: false);
  final List<ValidationDiagnostic> warnings = report.diagnostics
      .where(
          (ValidationDiagnostic d) => d.severity == DiagnosticSeverity.warning)
      .toList(growable: false);
  final List<ValidationDiagnostic> infos = report.diagnostics
      .where((ValidationDiagnostic d) => d.severity == DiagnosticSeverity.info)
      .toList(growable: false);

  if (errors.isNotEmpty) {
    sb.writeln('## Errors');
    sb.writeln();
    for (final ValidationDiagnostic d in errors) {
      sb.writeln('- **[${d.code}]** ${d.message}');
    }
    sb.writeln();
  }

  if (warnings.isNotEmpty) {
    sb.writeln('## Warnings');
    sb.writeln();
    for (final ValidationDiagnostic d in warnings) {
      sb.writeln('- **[${d.code}]** ${d.message}');
    }
    sb.writeln();
  }

  if (infos.isNotEmpty) {
    sb.writeln('## Info');
    sb.writeln();
    for (final ValidationDiagnostic d in infos) {
      sb.writeln('- [${d.code}] ${d.message}');
    }
    sb.writeln();
  }

  return sb.toString();
}

String _statusBadge(CompatibilityStatus status) => switch (status) {
      CompatibilityStatus.compatible => '✅ compatible',
      CompatibilityStatus.partiallyCompatible => '⚠️ partiallyCompatible',
      CompatibilityStatus.configError => '❌ configError',
      CompatibilityStatus.needsEngineSupport => '🔧 needsEngineSupport',
      CompatibilityStatus.needsAuthSupport => '🔑 needsAuthSupport',
      CompatibilityStatus.blockedBySiteProtection =>
        '🚫 blockedBySiteProtection',
    };

String _featureBadge(FeatureStatus status) => switch (status) {
      FeatureStatus.compatible => '✅',
      FeatureStatus.partiallyCompatible => '⚠️',
      FeatureStatus.notDeclared => '—',
      FeatureStatus.inferred => '🔍 inferred',
      FeatureStatus.requiresPlugin => '🔌 requiresPlugin',
      FeatureStatus.configError => '❌',
      FeatureStatus.needsAuthSupport => '🔑',
      FeatureStatus.blockedBySiteProtection => '🚫',
      FeatureStatus.unsupported => '🚫 unsupported',
    };
