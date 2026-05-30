/// Severity of a [ValidationDiagnostic] emitted by static or fixture/live
/// validation runs.
enum DiagnosticSeverity {
  /// Informational. No action required.
  info,

  /// Tolerable — the config can still run but a follow-up is recommended.
  warning,

  /// Blocking. The affected feature cannot be considered compatible.
  error,
}
