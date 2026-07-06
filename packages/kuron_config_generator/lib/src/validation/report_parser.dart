import 'dart:convert';

import 'package:kuron_core/kuron_core.dart';

/// Represents a parsed validation report from the validator CLI.
class ParsedReport {
  final String sourceId;
  final String overallStatus;
  final Map<String, String> featureStatuses;
  final List<ReportDiagnostic> diagnostics;

  const ParsedReport({
    required this.sourceId,
    required this.overallStatus,
    this.featureStatuses = const {},
    this.diagnostics = const [],
  });

  factory ParsedReport.fromJson(Map<String, Object?> json) {
    final sourceId = json['sourceId'];
    final overallStatus = json['overallStatus'];
    if (sourceId is! String || overallStatus is! String) {
      throw FormatException('Missing required fields: sourceId, overallStatus');
    }

    return ParsedReport(
      sourceId: sourceId,
      overallStatus: overallStatus,
      featureStatuses: (json['featureStatuses'] as Map<String, Object?>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          const {},
      diagnostics: (json['diagnostics'] as List<Object?>?)
              ?.map((d) => ReportDiagnostic.fromJson(d as Map<String, Object?>))
              .toList() ??
          const [],
    );
  }
}

/// A single diagnostic entry from a validation report.
class ReportDiagnostic {
  final String severity;
  final String code;
  final String message;
  final String? feature;

  const ReportDiagnostic({
    required this.severity,
    required this.code,
    required this.message,
    this.feature,
  });

  factory ReportDiagnostic.fromJson(Map<String, Object?> json) {
    final featureRaw = json['feature'] as String?;
    // R2.2: set to null if feature name doesn't match a known FeatureKind
    String? feature;
    if (featureRaw != null && featureRaw.isNotEmpty) {
      try {
        FeatureKind.values.byName(featureRaw);
        feature = featureRaw;
      } on ArgumentError {
        feature = null;
      }
    }
    return ReportDiagnostic(
      severity: json['severity'] as String? ?? 'error',
      code: json['code'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      feature: feature,
    );
  }
}

/// Parses validator JSON output into a [ParsedReport].
class ReportParser {
  static ParsedReport parse(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, Object?>;
    return ParsedReport.fromJson(json);
  }
}
