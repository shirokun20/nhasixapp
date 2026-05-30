import 'package:kuron_core/kuron_core.dart';
import 'package:test/test.dart';

void main() {
  group('FeatureContract', () {
    test('exposes required primitives/plugins and serializes', () {
      final FeatureContract contract = FeatureContract(
        feature: FeatureKind.reader,
        declared: true,
        required: true,
        requiredPrimitives: <String>{
          EnginePrimitive.imageModeTemplate,
          EnginePrimitive.headersStatic,
        },
        requiredPlugins: <String>{PluginCapability.cloudflareWebview},
        notes: 'derived from scraper.urlPatterns.reader',
      );

      expect(contract.feature, FeatureKind.reader);
      expect(contract.declared, isTrue);
      expect(contract.required, isTrue);
      expect(contract.requiredPrimitives,
          containsAll(<String>['imageMode.template', 'headers.static']));
      expect(contract.requiredPlugins,
          contains(PluginCapability.cloudflareWebview));

      final Map<String, Object?> json = contract.toJson();
      expect(json['feature'], 'reader');
      expect(json['required'], true);
      expect(
        json['requiredPrimitives'] as List<Object?>,
        contains('imageMode.template'),
      );
    });

    test('requiredPrimitives and requiredPlugins are immutable', () {
      final FeatureContract contract = FeatureContract(
        feature: FeatureKind.reader,
        declared: true,
        requiredPrimitives: <String>{EnginePrimitive.imageModeTemplate},
      );
      expect(
        () => (contract.requiredPrimitives).add('x'),
        throwsUnsupportedError,
      );
    });
  });

  group('SourceCapabilityDeclaration', () {
    SourceCapabilityDeclaration buildDeclaration() {
      return SourceCapabilityDeclaration(
        sourceId: 'ehentai',
        schemaVersion: '2.0',
        minEngineVersion: '1.0.0',
        contracts: <FeatureContract>[
          FeatureContract(
            feature: FeatureKind.home,
            declared: true,
            required: true,
            requiredPrimitives: <String>{EnginePrimitive.paginationPage},
          ),
          FeatureContract(
            feature: FeatureKind.reader,
            declared: true,
            required: true,
            requiredPlugins: <String>{
              PluginCapability.ehentaiPageTokenFetch,
            },
          ),
          FeatureContract(
            feature: FeatureKind.download,
            declared: true,
            requiredPrimitives: <String>{EnginePrimitive.headersStatic},
          ),
        ],
        vendorExtensions: <String, Object?>{
          'auth': <String, Object?>{'preferExhentai': false},
        },
      );
    }

    test('contractFor returns the matching contract or null', () {
      final SourceCapabilityDeclaration d = buildDeclaration();
      expect(d.contractFor(FeatureKind.reader)?.feature, FeatureKind.reader);
      expect(d.contractFor(FeatureKind.comments), isNull);
    });

    test('aggregates required primitives, plugins, and features', () {
      final SourceCapabilityDeclaration d = buildDeclaration();
      expect(
        d.allRequiredPrimitives,
        containsAll(<String>[
          EnginePrimitive.paginationPage,
          EnginePrimitive.headersStatic,
        ]),
      );
      expect(
        d.allRequiredPlugins,
        contains(PluginCapability.ehentaiPageTokenFetch),
      );
      expect(
        d.requiredFeatures,
        equals(<FeatureKind>{FeatureKind.home, FeatureKind.reader}),
      );
    });

    test('toJson includes vendorExtensions when present', () {
      final Map<String, Object?> json = buildDeclaration().toJson();
      expect(json['sourceId'], 'ehentai');
      expect(json['schemaVersion'], '2.0');
      expect(json['minEngineVersion'], '1.0.0');
      expect(json.containsKey('vendorExtensions'), isTrue);
    });
  });

  group('ValidationDiagnostic', () {
    test('copyWith and toJson preserve fields', () {
      const ValidationDiagnostic d = ValidationDiagnostic(
        severity: DiagnosticSeverity.warning,
        code: 'schemaVersionMissing',
        message: 'no schemaVersion declared',
        feature: FeatureKind.home,
        path: 'schemaVersion',
        context: <String, Object?>{'observed': null},
      );
      final ValidationDiagnostic upgraded =
          d.copyWith(severity: DiagnosticSeverity.error);
      expect(upgraded.severity, DiagnosticSeverity.error);
      expect(upgraded.code, 'schemaVersionMissing');

      final Map<String, Object?> json = upgraded.toJson();
      expect(json['severity'], 'error');
      expect(json['code'], 'schemaVersionMissing');
      expect(json['feature'], 'home');
      expect(json['path'], 'schemaVersion');
    });
  });
}
