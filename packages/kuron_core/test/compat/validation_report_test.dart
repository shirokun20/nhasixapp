import 'package:kuron_core/kuron_core.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationReport.computeOverallStatus', () {
    test('returns compatible when all features compatible/inferred', () {
      final CompatibilityStatus status = ValidationReport.computeOverallStatus(
        featureStatuses: <FeatureKind, FeatureStatus>{
          FeatureKind.home: FeatureStatus.compatible,
          FeatureKind.search: FeatureStatus.compatible,
          FeatureKind.reader: FeatureStatus.inferred,
          FeatureKind.download: FeatureStatus.notDeclared,
        },
        requiredFeatures: <FeatureKind>{
          FeatureKind.home,
          FeatureKind.search,
          FeatureKind.reader,
        },
        diagnostics: const <ValidationDiagnostic>[],
      );
      expect(status, CompatibilityStatus.compatible);
    });

    test('degrades to partiallyCompatible when only optional fails', () {
      final CompatibilityStatus status = ValidationReport.computeOverallStatus(
        featureStatuses: <FeatureKind, FeatureStatus>{
          FeatureKind.home: FeatureStatus.compatible,
          FeatureKind.reader: FeatureStatus.compatible,
          FeatureKind.download: FeatureStatus.configError,
        },
        requiredFeatures: <FeatureKind>{
          FeatureKind.home,
          FeatureKind.reader,
        },
        diagnostics: const <ValidationDiagnostic>[],
      );
      expect(status, CompatibilityStatus.partiallyCompatible);
    });

    test('returns needsEngineSupport when required feature needs a plugin', () {
      final CompatibilityStatus status = ValidationReport.computeOverallStatus(
        featureStatuses: <FeatureKind, FeatureStatus>{
          FeatureKind.reader: FeatureStatus.requiresPlugin,
        },
        requiredFeatures: <FeatureKind>{FeatureKind.reader},
        diagnostics: const <ValidationDiagnostic>[],
        missingPlugins: const <String>{PluginCapability.ehentaiPageTokenFetch},
      );
      expect(status, CompatibilityStatus.needsEngineSupport);
    });

    test('returns needsAuthSupport when required feature needs auth', () {
      final CompatibilityStatus status = ValidationReport.computeOverallStatus(
        featureStatuses: <FeatureKind, FeatureStatus>{
          FeatureKind.detail: FeatureStatus.needsAuthSupport,
        },
        requiredFeatures: <FeatureKind>{FeatureKind.detail},
        diagnostics: const <ValidationDiagnostic>[],
      );
      expect(status, CompatibilityStatus.needsAuthSupport);
    });

    test('returns blockedBySiteProtection when required feature blocked', () {
      final CompatibilityStatus status = ValidationReport.computeOverallStatus(
        featureStatuses: <FeatureKind, FeatureStatus>{
          FeatureKind.home: FeatureStatus.blockedBySiteProtection,
        },
        requiredFeatures: <FeatureKind>{FeatureKind.home},
        diagnostics: const <ValidationDiagnostic>[],
      );
      expect(status, CompatibilityStatus.blockedBySiteProtection);
    });
  });

  group('ValidationReport equality and JSON', () {
    test('equal reports compare equal regardless of generatedAt', () {
      final ValidationReport a = ValidationReport(
        sourceId: 'nhentai',
        overallStatus: CompatibilityStatus.compatible,
        featureStatuses: <FeatureKind, FeatureStatus>{
          FeatureKind.home: FeatureStatus.compatible,
        },
        generatedAt: DateTime.utc(2026, 1, 1),
      );
      final ValidationReport b = ValidationReport(
        sourceId: 'nhentai',
        overallStatus: CompatibilityStatus.compatible,
        featureStatuses: <FeatureKind, FeatureStatus>{
          FeatureKind.home: FeatureStatus.compatible,
        },
        generatedAt: DateTime.utc(2026, 5, 30),
      );
      expect(a, equals(b));
    });

    test('toJson contains stable fields', () {
      final ValidationReport report = ValidationReport(
        sourceId: 'mangadex',
        overallStatus: CompatibilityStatus.partiallyCompatible,
        featureStatuses: <FeatureKind, FeatureStatus>{
          FeatureKind.search: FeatureStatus.compatible,
          FeatureKind.download: FeatureStatus.unsupported,
        },
        schemaVersion: '2.0',
        engineVersion: '1.0.0',
        minEngineVersion: '1.0.0',
        diagnostics: <ValidationDiagnostic>[
          const ValidationDiagnostic(
            severity: DiagnosticSeverity.warning,
            code: 'downloadNotDeclared',
            message: 'download was not declared in features',
            feature: FeatureKind.download,
          ),
        ],
        requiredPlugins: <String>{PluginCapability.cloudflareWebview},
        detectedPlugins: <String>{PluginCapability.cloudflareWebview},
      );

      final Map<String, Object?> json = report.toJson();
      expect(json['sourceId'], 'mangadex');
      expect(json['overallStatus'], 'partiallyCompatible');
      expect(json['schemaVersion'], '2.0');
      final Map<String, Object?> features =
          json['featureStatuses']! as Map<String, Object?>;
      expect(features['search'], 'compatible');
      expect(features['download'], 'unsupported');
      final List<Object?> diags = json['diagnostics']! as List<Object?>;
      expect(diags, hasLength(1));
    });
  });

  group('ValidationReport helpers', () {
    test('diagnosticsFor filters by feature', () {
      final ValidationReport report = ValidationReport(
        sourceId: 'x',
        overallStatus: CompatibilityStatus.compatible,
        featureStatuses: const <FeatureKind, FeatureStatus>{},
        diagnostics: <ValidationDiagnostic>[
          const ValidationDiagnostic(
            severity: DiagnosticSeverity.info,
            code: 'a',
            message: 'a',
            feature: FeatureKind.home,
          ),
          const ValidationDiagnostic(
            severity: DiagnosticSeverity.warning,
            code: 'b',
            message: 'b',
            feature: FeatureKind.reader,
          ),
        ],
      );
      expect(report.diagnosticsFor(FeatureKind.home), hasLength(1));
      expect(report.diagnosticsFor(FeatureKind.download), isEmpty);
      expect(report.hasErrors, isFalse);
      expect(report.hasWarnings, isTrue);
    });
  });
}
