#!/usr/bin/env dart

/// kuron_config_validate — CLI entry point for source config validation.
///
/// Usage:
///   `dart run kuron_generic:kuron_config_validate [options] <config.json>...`
///   `dart run kuron_generic:kuron_config_validate [options] --dir <configs/>`
///
/// Options:
///   `--format json|markdown|text`   Output format (default: text)
///   `--output <path>`               Write report to file instead of stdout
///   `--dir <directory>`             Validate all *.json files in directory
///   `--engine <version>`            Override engine version (default: 2.0.0)
///   `--fail-on <status,...>`        Exit non-zero when any source matches status
///                                 (default: configError,needsEngineSupport)
///   --help                        Show this help
///
/// Exit codes (task 4.6):
///   0  All sources compatible
///   1  One or more sources partially compatible (optional features missing)
///   2  One or more config errors
///   3  One or more sources need engine support
///   4  One or more sources need auth support
///   5  One or more sources blocked by site protection
///   64 Usage error
library;

import 'dart:convert';
import 'dart:io';

import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/kuron_generic.dart';

const String _kVersion = '2.0.0';

void main(List<String> args) async {
  final _CliOptions opts;
  try {
    opts = _CliOptions.parse(args);
  } on _UsageError catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln();
    _printHelp();
    exit(64);
  }

  if (opts.showHelp) {
    _printHelp();
    exit(0);
  }

  // Collect config file paths.
  final List<File> files = <File>[];
  for (final String path in opts.configPaths) {
    final File f = File(path);
    if (!f.existsSync()) {
      stderr.writeln('File not found: $path');
      exit(64);
    }
    files.add(f);
  }
  if (opts.configDir != null) {
    final Directory d = Directory(opts.configDir!);
    if (!d.existsSync()) {
      stderr.writeln('Directory not found: ${opts.configDir}');
      exit(64);
    }
    files.addAll(
      d
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.json'))
          .toList(growable: false),
    );
  }

  if (files.isEmpty) {
    stderr.writeln('No config files specified.');
    _printHelp();
    exit(64);
  }

  final SourceConfigParser parser =
      SourceConfigParser(engineVersion: opts.engineVersion);

  // Determine output sink.
  final IOSink out =
      opts.outputPath != null ? File(opts.outputPath!).openWrite() : stdout;

  final List<ValidationReport> reports = <ValidationReport>[];

  for (final File f in files) {
    Map<String, Object?> raw;
    try {
      raw = (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();
    } catch (e) {
      stderr.writeln('Failed to parse JSON in ${f.path}: $e');
      reports.add(_errorReport(f.path, 'jsonParseError', e.toString()));
      continue;
    }

    final SourceConfigParseResult result = parser.parse(raw);
    reports.add(result.report);

    // Write report to output.
    final String block = switch (opts.format) {
      _OutputFormat.json => reportToJson(result.report),
      _OutputFormat.markdown => reportToMarkdown(result.report),
      _OutputFormat.text => _textReport(result.report),
    };

    out.writeln(block);
    if (opts.format == _OutputFormat.text) {
      out.writeln(); // blank line between sources
    }
  }

  if (opts.outputPath != null) {
    await out.flush();
    await out.close();
  }

  // Compute exit code (task 4.6).
  final int exitCode = _computeExitCode(reports, opts.failOn);
  exit(exitCode);
}

// ── Exit code logic ──────────────────────────────────────────────────────────

int _computeExitCode(
  List<ValidationReport> reports,
  Set<String> failOn,
) {
  CompatibilityStatus worst = CompatibilityStatus.compatible;
  for (final ValidationReport r in reports) {
    final CompatibilityStatus s = r.overallStatus;
    if (_statusRank(s) > _statusRank(worst)) worst = s;
  }
  if (!failOn.contains(worst.name) && worst != CompatibilityStatus.compatible) {
    return 0; // Caller opted out of this failure level.
  }
  return switch (worst) {
    CompatibilityStatus.compatible => 0,
    CompatibilityStatus.partiallyCompatible => 1,
    CompatibilityStatus.configError => 2,
    CompatibilityStatus.needsEngineSupport => 3,
    CompatibilityStatus.needsAuthSupport => 4,
    CompatibilityStatus.blockedBySiteProtection => 5,
  };
}

int _statusRank(CompatibilityStatus s) => switch (s) {
      CompatibilityStatus.compatible => 0,
      CompatibilityStatus.partiallyCompatible => 1,
      CompatibilityStatus.needsAuthSupport => 2,
      CompatibilityStatus.needsEngineSupport => 3,
      CompatibilityStatus.configError => 4,
      CompatibilityStatus.blockedBySiteProtection => 5,
    };

// ── Text format ──────────────────────────────────────────────────────────────

String _textReport(ValidationReport report) {
  final StringBuffer sb = StringBuffer();
  sb.writeln('Source : ${report.sourceId}');
  sb.writeln('Status : ${report.overallStatus.name}');

  if (report.featureStatuses.isNotEmpty) {
    sb.writeln('Features:');
    for (final MapEntry<FeatureKind, FeatureStatus> e
        in report.featureStatuses.entries) {
      sb.writeln('  ${e.key.name.padRight(16)}: ${e.value.name}');
    }
  }

  final List<ValidationDiagnostic> errors = report.diagnosticsOf(
    severity: DiagnosticSeverity.error,
  );
  final List<ValidationDiagnostic> warnings = report.diagnosticsOf(
    severity: DiagnosticSeverity.warning,
  );

  if (errors.isNotEmpty) {
    sb.writeln('Errors:');
    for (final ValidationDiagnostic d in errors) {
      sb.writeln('  [${d.code}] ${d.message}');
    }
  }
  if (warnings.isNotEmpty) {
    sb.writeln('Warnings:');
    for (final ValidationDiagnostic d in warnings) {
      sb.writeln('  [${d.code}] ${d.message}');
    }
  }

  return sb.toString();
}

// ── Error report stub ────────────────────────────────────────────────────────

ValidationReport _errorReport(String path, String code, String message) {
  return ValidationReport(
    sourceId: path,
    overallStatus: CompatibilityStatus.configError,
    featureStatuses: const <FeatureKind, FeatureStatus>{},
    diagnostics: <ValidationDiagnostic>[
      ValidationDiagnostic(
        severity: DiagnosticSeverity.error,
        code: code,
        message: message,
      ),
    ],
    mode: ValidationMode.staticMode,
  );
}

// ── CLI option parsing ────────────────────────────────────────────────────────

enum _OutputFormat { json, markdown, text }

class _UsageError {
  const _UsageError(this.message);
  final String message;
}

class _CliOptions {
  const _CliOptions({
    required this.configPaths,
    required this.format,
    required this.engineVersion,
    required this.failOn,
    required this.showHelp,
    this.configDir,
    this.outputPath,
  });

  final List<String> configPaths;
  final _OutputFormat format;
  final String engineVersion;
  final Set<String> failOn;
  final bool showHelp;
  final String? configDir;
  final String? outputPath;

  factory _CliOptions.parse(List<String> args) {
    final List<String> paths = <String>[];
    _OutputFormat format = _OutputFormat.text;
    String engineVersion = _kVersion;
    Set<String> failOn = <String>{'configError', 'needsEngineSupport'};
    bool showHelp = false;
    String? configDir;
    String? outputPath;

    for (int i = 0; i < args.length; i++) {
      final String a = args[i];
      switch (a) {
        case '--help':
        case '-h':
          showHelp = true;
        case '--dir':
          i++;
          if (i >= args.length) {
            throw const _UsageError('--dir requires a path');
          }
          configDir = args[i];
        case '--output':
          i++;
          if (i >= args.length) {
            throw const _UsageError('--output requires a path');
          }
          outputPath = args[i];
        case '--format':
          i++;
          if (i >= args.length) {
            throw const _UsageError('--format requires json|markdown|text');
          }
          format = switch (args[i]) {
            'json' => _OutputFormat.json,
            'markdown' => _OutputFormat.markdown,
            'text' => _OutputFormat.text,
            _ => throw _UsageError('Unknown format: ${args[i]}'),
          };
        case '--engine':
          i++;
          if (i >= args.length) {
            throw const _UsageError('--engine requires a version string');
          }
          engineVersion = args[i];
        case '--fail-on':
          i++;
          if (i >= args.length) {
            throw const _UsageError(
                '--fail-on requires comma-separated statuses');
          }
          failOn = args[i].split(',').toSet();
        default:
          if (a.startsWith('-')) throw _UsageError('Unknown option: $a');
          paths.add(a);
      }
    }

    return _CliOptions(
      configPaths: paths,
      format: format,
      engineVersion: engineVersion,
      failOn: failOn,
      showHelp: showHelp,
      configDir: configDir,
      outputPath: outputPath,
    );
  }
}

void _printHelp() {
  stdout.writeln('''
kuron_config_validate v$_kVersion

Usage:
  dart run kuron_generic:kuron_config_validate [options] <config.json>...
  dart run kuron_generic:kuron_config_validate --dir <configs/>

Options:
  --format json|markdown|text   Output format (default: text)
  --output <path>               Write report to file instead of stdout
  --dir <directory>             Validate all *.json in directory
  --engine <version>            Override engine version (default: $_kVersion)
  --fail-on <status,...>        Exit non-zero on matching status
                                (default: configError,needsEngineSupport)
  --help                        Show this help

Exit codes:
  0  All compatible
  1  Partially compatible (optional features missing)
  2  Config errors
  3  Needs engine support
  4  Needs auth support
  5  Blocked by site protection
  64 Usage error
''');
}
