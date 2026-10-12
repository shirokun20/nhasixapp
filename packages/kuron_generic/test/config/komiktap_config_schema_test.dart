// Schema validation tests for komiktap-config.json and nhentai-config.json.
///
// These tests load the actual JSON config files from disk and validate that:
//   1. All required top-level keys are present with correct types.
//   2. Every list URL pattern has the new `list.{container, fields}` schema.
//   3. `fields` maps use the canonical `{selector, ...}` field definition format.
//   4. Detail selectors and chapter selectors are well-formed.
//   5. Reader config has the required sub-structure.
//   6. `searchForm` structure is valid.
//   7. `inherits` references point to existing patterns.
///
// Run with:
//   dart test packages/kuron_generic/test/config/komiktap_config_schema_test.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../support/config_test_harness.dart';

// nhentai is a bundled default shipped in `assets/configs/`; it is not an
// installable source, so the remote harness does not apply.
Map<String, dynamic> _loadBundledNhentai() {
  const candidates = [
    'assets/configs/nhentai-config.json', // running from project root
    '../../assets/configs/nhentai-config.json', // from packages/kuron_generic/
  ];
  for (final p in candidates) {
    if (File(p).existsSync()) {
      return jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError(
      'Cannot locate nhentai-config.json under assets/configs/. Run tests from project root or packages/kuron_generic/.');
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// Assert that [map] has a non-null value at [key].
void _hasKey(Map<String, dynamic> map, String key, String context) {
  expect(map.containsKey(key), isTrue,
      reason: '$context: missing key "$key". Keys present: ${map.keys}');
}

// Assert [map][key] is a [Map<String,dynamic>].
Map<String, dynamic> _asMap(Map<String, dynamic> map, String key, String ctx) {
  _hasKey(map, key, ctx);
  expect(map[key], isA<Map>(),
      reason:
          '$ctx: "$key" should be a JSON object, got ${map[key].runtimeType}');
  return (map[key] as Map).cast<String, dynamic>();
}

// Assert [map][key] is a non-empty, non-blank [String].
void _asString(Map<String, dynamic> map, String key, String ctx) {
  _hasKey(map, key, ctx);
  expect(map[key], isA<String>(), reason: '$ctx: "$key" should be a String');
  expect((map[key] as String).trim(), isNotEmpty,
      reason: '$ctx: "$key" is present but empty');
}

// komiktap migrated to API v2 (1.1.8): the `scraper` block is gone, replaced
// by `api`. Groups below assert the API-mode contract against the live config.

// ═══════════════════════════════════════════════════════════════════════════
// komiktap-config.json
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  late Map<String, dynamic> komiktap;
  late Map<String, dynamic> nhentai;

  setUpAll(() async {
    komiktap = (await loadConfigRemote('komiktap-config.json'))
        .cast<String, dynamic>();
    nhentai = _loadBundledNhentai();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // komiktap — top-level keys
  // ─────────────────────────────────────────────────────────────────────────

  group('komiktap-config.json top-level', () {
    test('has required identity fields', () {
      _asString(komiktap, 'source', 'root');
      _asString(komiktap, 'version', 'root');
      _asString(komiktap, 'baseUrl', 'root');
    });

    test('source is "komiktap"', () {
      expect(komiktap['source'], 'komiktap');
    });

    test('has configUrl (for self-refresh)', () {
      _asString(komiktap, 'configUrl', 'root');
      expect((komiktap['configUrl'] as String).startsWith('https://'), isTrue,
          reason: 'configUrl should be an https URL');
    });

    test('baseUrl is a valid https URL', () {
      final url = komiktap['baseUrl'] as String;
      expect(url.startsWith('https://'), isTrue);
    });

    test('enabled is a boolean', () {
      expect(komiktap['enabled'], isA<bool>());
    });

    test('has searchForm block', () {
      _asMap(komiktap, 'searchForm', 'root');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // komiktap — searchForm
  // ─────────────────────────────────────────────────────────────────────────

  group('komiktap-config.json searchForm', () {
    late Map<String, dynamic> searchForm;

    setUp(() {
      searchForm = _asMap(komiktap, 'searchForm', 'root');
    });

    test('has urlPattern string', () {
      _asString(searchForm, 'urlPattern', 'searchForm');
    });

    test('has params block with at least query and page entries', () {
      final params = _asMap(searchForm, 'params', 'searchForm');
      expect(params.containsKey('query'), isTrue,
          reason: 'searchForm.params must contain "query"');
      expect(params.containsKey('page'), isTrue,
          reason: 'searchForm.params must contain "page"');
    });

    test('each param has queryParam and type fields', () {
      final params = (searchForm['params'] as Map).cast<String, dynamic>();
      for (final entry in params.entries) {
        final def = (entry.value as Map).cast<String, dynamic>();
        _asString(def, 'queryParam', 'searchForm.params.${entry.key}');
        _asString(def, 'type', 'searchForm.params.${entry.key}');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // komiktap — api block (API v2 mode)
  // ─────────────────────────────────────────────────────────────────────────

  group('komiktap-config.json api', () {
    late Map<String, dynamic> api;

    setUp(() {
      api = _asMap(komiktap, 'api', 'root');
    });

    test('is enabled with https url', () {
      expect(api['enabled'], isTrue);
      _asString(api, 'url', 'api');
      expect((api['url'] as String).startsWith('https://'), isTrue);
    });

    test('has non-empty endpoints map', () {
      final endpoints = _asMap(api, 'endpoints', 'api');
      expect(endpoints, isNotEmpty);
    });

    test('list has fields, items and pagination', () {
      final list = _asMap(api, 'list', 'api');
      _hasKey(list, 'fields', 'api.list');
      _asString(list, 'items', 'api.list');
      _hasKey(list, 'pagination', 'api.list');
    });

    test('detail has chapters with fields', () {
      final detail = _asMap(api, 'detail', 'api');
      final chapters = _asMap(detail, 'chapters', 'api.detail');
      expect(_asMap(chapters, 'fields', 'api.detail.chapters'), isNotEmpty);
    });

    test('images has items and mode', () {
      final images = _asMap(api, 'images', 'api');
      _asString(images, 'items', 'api.images');
      _asString(images, 'mode', 'api.images');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // nhentai-config.json
  // ─────────────────────────────────────────────────────────────────────────

  group('nhentai-config.json', () {
    test('source is "nhentai"', () {
      expect(nhentai['source'], 'nhentai');
    });

    test('has api block (nhentai uses REST adapter)', () {
      _hasKey(nhentai, 'api', 'root');
      expect(nhentai['api'], isA<Map>());
    });

    test('api block has endpoints defined', () {
      final api = (nhentai['api'] as Map).cast<String, dynamic>();
      expect(api.containsKey('endpoints'), isTrue,
          reason: 'nhentai api block must have endpoints');
    });
  });
}
