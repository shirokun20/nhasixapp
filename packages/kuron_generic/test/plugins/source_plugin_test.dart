/// Tests for SourcePluginRegistry (task 6.5).
library;

import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_generic/src/plugins/source_plugin.dart';
import 'package:test/test.dart';

// ── Stub plugins ─────────────────────────────────────────────────────────────

class _StubImagePlugin implements ImageUrlTransformPlugin {
  const _StubImagePlugin(this.capability);
  @override
  final String capability;

  @override
  Future<List<String>> transformImageUrls({
    required List<String> rawUrls,
    required Map<String, Object?> rawConfig,
    required Map<String, String> sessionHeaders,
  }) async =>
      rawUrls.map((String u) => '$u?transformed').toList(growable: false);
}

class _StubAuthPlugin implements SourceAuthPlugin {
  @override
  String get capability => PluginCapability.cloudflareWebview;

  @override
  Future<SourceAuthResult> prepareSession(
    String sourceId,
    Map<String, Object?> rawConfig,
  ) async =>
      const SourceAuthResult(
        success: true,
        headers: <String, String>{'CF-Token': 'stub'},
      );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late SourcePluginRegistry registry;

  setUp(() {
    registry = SourcePluginRegistry.instance..reset();
  });

  tearDown(() => registry.reset());

  group('SourcePluginRegistry', () {
    test('register and has', () {
      registry.register(
          const _StubImagePlugin(PluginCapability.hentainexusDecrypt));
      expect(registry.has(PluginCapability.hentainexusDecrypt), isTrue);
    });

    test('unregister removes plugin', () {
      registry.register(
          const _StubImagePlugin(PluginCapability.hentainexusDecrypt));
      registry.unregister(PluginCapability.hentainexusDecrypt);
      expect(registry.has(PluginCapability.hentainexusDecrypt), isFalse);
    });

    test('getAs returns typed plugin', () {
      registry.register(
          const _StubImagePlugin(PluginCapability.hentainexusDecrypt));
      final ImageUrlTransformPlugin? p = registry
          .getAs<ImageUrlTransformPlugin>(PluginCapability.hentainexusDecrypt);
      expect(p, isNotNull);
    });

    test('getAs returns null for wrong type', () {
      registry.register(
          const _StubImagePlugin(PluginCapability.hentainexusDecrypt));
      final SourceAuthPlugin? p =
          registry.getAs<SourceAuthPlugin>(PluginCapability.hentainexusDecrypt);
      expect(p, isNull);
    });

    test('registeredCapabilities reflects all plugins', () {
      registry
        ..register(const _StubImagePlugin(PluginCapability.hentainexusDecrypt))
        ..register(_StubAuthPlugin());
      expect(
        registry.registeredCapabilities,
        containsAll(<String>[
          PluginCapability.hentainexusDecrypt,
          PluginCapability.cloudflareWebview,
        ]),
      );
    });

    test('toParser uses registeredCapabilities', () {
      registry.register(
          const _StubImagePlugin(PluginCapability.hentainexusDecrypt));
      final parser = registry.toParser();
      // The parser should mark hentainexus.decrypt as detected.
      final result = parser.parse(<String, Object?>{
        'source': 'hentainexus',
        'decryption': <String, Object?>{'method': 'xor'},
        'scraper': <String, Object?>{
          'enabled': true,
          'urlPatterns': <String, Object?>{
            'home': <String, Object?>{'url': '/'},
            'detail': '/view/{id}',
            'chapter': '/read/{id}',
          },
        },
      });
      final FeatureStatus? reader =
          result.report.featureStatuses[FeatureKind.reader];
      expect(
        reader ?? FeatureStatus.notDeclared,
        anyOf(FeatureStatus.compatible, FeatureStatus.inferred),
        reason: 'reader should be compatible when plugin is registered',
      );
    });

    test('reset clears all plugins', () {
      registry
        ..register(const _StubImagePlugin(PluginCapability.hentainexusDecrypt))
        ..register(_StubAuthPlugin());
      registry.reset();
      expect(registry.registeredCapabilities, isEmpty);
    });
  });

  group('PluginCapabilityReport', () {
    test('isComplete when no missing', () {
      final SourceCapabilityDeclaration decl = SourceCapabilityDeclaration(
        sourceId: 'x',
        schemaVersion: 'v1',
        contracts: <FeatureContract>[
          FeatureContract(
            feature: FeatureKind.reader,
            declared: true,
            required: true,
            requiredPlugins: <String>{PluginCapability.hentainexusDecrypt},
          ),
        ],
      );
      registry.register(
          const _StubImagePlugin(PluginCapability.hentainexusDecrypt));
      final PluginCapabilityReport report = registry.reportFor(decl);
      expect(report.isComplete, isTrue);
      expect(report.missing, isEmpty);
    });

    test('not complete when plugin missing', () {
      final SourceCapabilityDeclaration decl = SourceCapabilityDeclaration(
        sourceId: 'x',
        schemaVersion: 'v1',
        contracts: <FeatureContract>[
          FeatureContract(
            feature: FeatureKind.reader,
            declared: true,
            required: true,
            requiredPlugins: <String>{PluginCapability.hitomiNozomi},
          ),
        ],
      );
      final PluginCapabilityReport report = registry.reportFor(decl);
      expect(report.isComplete, isFalse);
      expect(report.missing, contains(PluginCapability.hitomiNozomi));
    });
  });

  group('SourceAuthPlugin stub', () {
    test('prepareSession returns success with headers', () async {
      final _StubAuthPlugin plugin = _StubAuthPlugin();
      final SourceAuthResult result =
          await plugin.prepareSession('crotpedia', <String, Object?>{});
      expect(result.success, isTrue);
      expect(result.headers['CF-Token'], 'stub');
    });
  });

  group('ImageUrlTransformPlugin stub', () {
    test('transformImageUrls appends ?transformed', () async {
      const _StubImagePlugin plugin =
          _StubImagePlugin(PluginCapability.hentainexusDecrypt);
      final List<String> out = await plugin.transformImageUrls(
        rawUrls: <String>['https://x.com/p1.jpg', 'https://x.com/p2.jpg'],
        rawConfig: <String, Object?>{},
        sessionHeaders: <String, String>{},
      );
      expect(out, <String>[
        'https://x.com/p1.jpg?transformed',
        'https://x.com/p2.jpg?transformed',
      ]);
    });
  });
}
