import 'package:equatable/equatable.dart';

import 'diagnostic_severity.dart';
import 'feature_kind.dart';

/// A single diagnostic produced by static, fixture, or live validation.
///
/// All free-form context values must be passed through `SecretRedactor`
/// before being stored on a diagnostic so persisted/reported diagnostics
/// never carry raw cookies, tokens, or signed URLs.
class ValidationDiagnostic extends Equatable {
  const ValidationDiagnostic({
    required this.severity,
    required this.code,
    required this.message,
    this.feature,
    this.path,
    this.context = const <String, Object?>{},
  });

  /// Severity level. Validators must promote any diagnostic that blocks a
  /// declared required feature to [DiagnosticSeverity.error].
  final DiagnosticSeverity severity;

  /// Stable machine-readable code (e.g. `schemaVersionMissing`,
  /// `contentIdPatternMissing`). Use camelCase. New codes must be appended
  /// without renaming existing ones to keep external tooling stable.
  final String code;

  /// Human-readable explanation.
  final String message;

  /// Feature this diagnostic applies to, when applicable.
  final FeatureKind? feature;

  /// Dotted JSON path of the offending config field, when applicable.
  /// Example: `scraper.urlPatterns.detail.url`.
  final String? path;

  /// Pre-redacted structured context. Never put raw cookies, tokens, or
  /// signed URLs here. Use `SecretRedactor` upstream.
  final Map<String, Object?> context;

  ValidationDiagnostic copyWith({
    DiagnosticSeverity? severity,
    String? code,
    String? message,
    FeatureKind? feature,
    String? path,
    Map<String, Object?>? context,
  }) {
    return ValidationDiagnostic(
      severity: severity ?? this.severity,
      code: code ?? this.code,
      message: message ?? this.message,
      feature: feature ?? this.feature,
      path: path ?? this.path,
      context: context ?? this.context,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'severity': severity.name,
        'code': code,
        'message': message,
        if (feature != null) 'feature': feature!.name,
        if (path != null) 'path': path,
        if (context.isNotEmpty) 'context': context,
      };

  @override
  List<Object?> get props => <Object?>[
        severity,
        code,
        message,
        feature,
        path,
        context,
      ];
}
