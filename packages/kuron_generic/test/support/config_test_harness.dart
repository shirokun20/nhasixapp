/// Shared config validation test harness (task 4.7 + 4.8).
///
/// Usage — in any test file, call [runConfigContractTests]:
/// ```dart
/// runConfigContractTests(
///   configName: 'mangadex-config.json',
///   expectedOverallStatus: CompatibilityStatus.compatible,
///   expectedFeatures: {FeatureKind.search: FeatureStatus.inferred},
///   expectedDiagCodes: {'schemaVersionMissing'},
/// );
/// ```
///
/// The harness locates configs via a standard search path relative to the
/// Dart working directory (works from both workspace root and from
/// `packages/kuron_generic/`).
library;

import 'dart:convert';
import 'dart:io';

import 'package:kuron_core/kuron_core.dart';
import 'package:test/test.dart';

import 'package:kuron_generic/src/config/source_config_parser.dart';

/// Locate a config file by [name] in the standard search paths.
///
/// Searches (in order):
///   - `../../informations/configs/<name>` (from packages/kuron_generic/)
///   - `informations/configs/<name>` (from workspace root)
Map<String, Object?> loadConfig(String name) {
  final List<String> candidates = <String>[
    '../../informations/configs/$name',
    'informations/configs/$name',
  ];
  for (final String path in candidates) {
    final File f = File(path);
    if (f.existsSync()) {
      return (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();
    }
  }
  throw StateError(
    'Cannot locate config $name. Run tests from workspace root or '
    'packages/kuron_generic/.',
  );
}

/// Metadata describing the expected outcome for one source config.
class ConfigContractCase {
  const ConfigContractCase({
    required this.configName,
    this.expectedOverallStatus,
    this.expectedFeatures = const <FeatureKind, FeatureStatus>{},
    this.expectedDiagCodes = const <String>{},
    this.forbiddenDiagCodes = const <String>{},
    this.registeredPlugins = const <String>{},
  });

  /// File name inside `informations/configs/`.
  final String configName;

  /// If set, the overall [CompatibilityStatus] must match exactly.
  final CompatibilityStatus? expectedOverallStatus;

  /// Per-feature expectations. Only listed features are verified.
  final Map<FeatureKind, FeatureStatus> expectedFeatures;

  /// Diagnostic codes that MUST appear in the report.
  final Set<String> expectedDiagCodes;

  /// Diagnostic codes that MUST NOT appear.
  final Set<String> forbiddenDiagCodes;

  /// Plugins to register for this test run.
  final Set<String> registeredPlugins;
}

/// Registers a `group` of tests from [cases] using the shared harness.
///
/// Each [ConfigContractCase] becomes a `group` with individual `test` entries
/// for overall status, per-feature status, and diagnostics.
///
/// Pass [parserFactory] to use a custom [SourceConfigParser]; otherwise the
/// default (no registered primitives / plugins) is used.
void runConfigContractTests(
  List<ConfigContractCase> cases, {
  SourceConfigParser Function(ConfigContractCase)? parserFactory,
}) {
  for (final ConfigContractCase c in cases) {
    group(c.configName, () {
      late SourceConfigParseResult result;

      setUpAll(() {
        final SourceConfigParser parser = parserFactory != null
            ? parserFactory(c)
            : SourceConfigParser(registeredPlugins: c.registeredPlugins);
        result = parser.parse(loadConfig(c.configName));
      });

      if (c.expectedOverallStatus != null) {
        test('overall status is ${c.expectedOverallStatus!.name}', () {
          expect(result.report.overallStatus, c.expectedOverallStatus);
        });
      }

      for (final MapEntry<FeatureKind, FeatureStatus> e
          in c.expectedFeatures.entries) {
        test('feature ${e.key.name} is ${e.value.name}', () {
          expect(
            result.report.featureStatuses[e.key] ?? FeatureStatus.notDeclared,
            e.value,
            reason: '${e.key.name} should be ${e.value.name}',
          );
        });
      }

      for (final String code in c.expectedDiagCodes) {
        test('diagnostic $code is present', () {
          expect(
            result.report.diagnostics
                .any((ValidationDiagnostic d) => d.code == code),
            isTrue,
            reason: 'Expected diagnostic code $code to be present',
          );
        });
      }

      for (final String code in c.forbiddenDiagCodes) {
        test('diagnostic $code is absent', () {
          expect(
            result.report.diagnostics
                .any((ValidationDiagnostic d) => d.code == code),
            isFalse,
            reason: 'Diagnostic code $code should NOT be present',
          );
        });
      }
    });
  }
}
