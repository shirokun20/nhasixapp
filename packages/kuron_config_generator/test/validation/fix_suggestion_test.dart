import 'dart:math';

import 'package:test/test.dart';
import 'package:kuron_config_generator/src/validation/fix_suggestion.dart';
import 'package:kuron_config_generator/src/validation/report_parser.dart';

void main() {
  group('FixSuggestion', () {
    test('fromJson round-trip preserves all fields', () {
      final original = FixSuggestion(
        diagnosticCode: 'test.code',
        suggestionText: 'Do the thing.',
        targetFeature: 'reader',
        configField: 'scraper.selectors.reader',
      );
      final json = {
        'diagnosticCode': 'test.code',
        'suggestionText': 'Do the thing.',
        'targetFeature': 'reader',
        'configField': 'scraper.selectors.reader',
      };
      final parsed = FixSuggestion.fromJson(json);
      expect(parsed.diagnosticCode, original.diagnosticCode);
      expect(parsed.suggestionText, original.suggestionText);
      expect(parsed.targetFeature, original.targetFeature);
      expect(parsed.configField, original.configField);
    });

    test('fromJson handles nullable fields', () {
      final json = {
        'diagnosticCode': 'no-extra',
        'suggestionText': 'Keep it simple.',
      };
      final parsed = FixSuggestion.fromJson(json);
      expect(parsed.diagnosticCode, 'no-extra');
      expect(parsed.suggestionText, 'Keep it simple.');
      expect(parsed.targetFeature, isNull);
      expect(parsed.configField, isNull);
    });
  });

  group('FixSuggestionMapper', () {
    group('known codes', () {
      test('schemaVersionMissing', () {
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(severity: 'error', code: 'schemaVersionMissing', message: 'x'),
        ]);
        expect(result, hasLength(1));
        expect(result[0].suggestionText,
            'Add `schemaVersion: 2.0` to the config.');
        expect(result[0].configField, 'schemaVersion');
      });

      test('contentIdPatternMissing', () {
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(severity: 'error', code: 'contentIdPatternMissing', message: 'x'),
        ]);
        expect(result, hasLength(1));
        expect(result[0].suggestionText,
            contains('contentIdPattern'));
        expect(result[0].configField, 'contentIdPattern');
      });

      test('homeUrlUnreachable', () {
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(severity: 'error', code: 'homeUrlUnreachable', message: 'x'),
        ]);
        expect(result, hasLength(1));
        expect(result[0].suggestionText, contains('baseUrl'));
        expect(result[0].configField, 'baseUrl');
      });

      test('reader.configError', () {
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(severity: 'error', code: 'reader.configError', message: 'x'),
        ]);
        expect(result, hasLength(1));
        expect(result[0].suggestionText, contains('scraper.selectors.reader'));
        expect(result[0].targetFeature, 'reader');
      });

      test('search.configError', () {
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(severity: 'error', code: 'search.configError', message: 'x'),
        ]);
        expect(result, hasLength(1));
        expect(result[0].suggestionText, contains('searchForm'));
        expect(result[0].targetFeature, 'search');
      });

      test('download.configError', () {
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(severity: 'error', code: 'download.configError', message: 'x'),
        ]);
        expect(result, hasLength(1));
        expect(result[0].suggestionText, contains('reader image pipeline'));
        expect(result[0].targetFeature, 'download');
      });
    });

    group('unknown code — generic fallback (R3.8)', () {
      test('includes feature name when present', () {
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(
            severity: 'error',
            code: 'some.weird.error',
            message: 'Something broke in the parser.',
            feature: 'reader',
          ),
        ]);
        expect(result, hasLength(1));
        expect(result[0].suggestionText,
            'Review the feature `reader` — see diagnostic: `Something broke in the parser.`.');
        expect(result[0].targetFeature, 'reader');
      });

      test('uses "Review the config" when no feature', () {
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(
            severity: 'error',
            code: 'some.unknown',
            message: 'Unexpected input.',
          ),
        ]);
        expect(result, hasLength(1));
        expect(result[0].suggestionText,
            'Review the config — see diagnostic: `Unexpected input.`.');
        expect(result[0].targetFeature, isNull);
      });

      test('fallback suggestion has generic diagnosticCode', () {
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(
            severity: 'error',
            code: 'mystery.error',
            message: '??',
          ),
        ]);
        expect(result[0].diagnosticCode, 'mystery.error');
      });
    });

    test('kFixSuggestions contains exactly 6 entries', () {
      expect(FixSuggestionMapper.kFixSuggestions, hasLength(6));
      expect(
        FixSuggestionMapper.kFixSuggestions.keys,
        unorderedEquals([
          'schemaVersionMissing',
          'contentIdPatternMissing',
          'homeUrlUnreachable',
          'reader.configError',
          'search.configError',
          'download.configError',
        ]),
      );
    });

    test('map handles multiple diagnostics in one call', () {
      final result = FixSuggestionMapper.map([
        ReportDiagnostic(severity: 'error', code: 'schemaVersionMissing', message: 'x'),
        ReportDiagnostic(severity: 'error', code: 'search.configError', message: 'x'),
        ReportDiagnostic(severity: 'error', code: 'unknown.code', message: 'Kaboom'),
      ]);
      expect(result, hasLength(3));
      expect(result[0].diagnosticCode, 'schemaVersionMissing');
      expect(result[1].diagnosticCode, 'search.configError');
      expect(result[2].diagnosticCode, 'unknown.code');
      expect(result[2].suggestionText, contains('Kaboom'));
    });

    test('map handles empty diagnostic list', () {
      final result = FixSuggestionMapper.map([]);
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Property tests — validates mapping invariants across random inputs (R3.1, R3.8)
  // ---------------------------------------------------------------------------
  group('property tests — suggestion coverage (R3.1, R3.8)', () {
    final rng = Random(42);

    Set<String> knownCodes() =>
        FixSuggestionMapper.kFixSuggestions.keys.toSet();

    String randomCode({required bool forceUnknown}) {
      final known = knownCodes();
      if (!forceUnknown && rng.nextBool() && known.isNotEmpty) {
        return known.elementAt(rng.nextInt(known.length));
      }
      final parts = rng.nextInt(4) + 1;
      return List.generate(
        parts,
        (_) => String.fromCharCodes(List.generate(
          rng.nextInt(8) + 2,
          (_) => rng.nextInt(26) + 97,
        )),
      ).join('.');
    }

    test('P1: known code always returns specific mapping (never fallback)', () {
      for (int i = 0; i < 200; i++) {
        final code = randomCode(forceUnknown: false);
        if (FixSuggestionMapper.kFixSuggestions.containsKey(code)) {
          final result = FixSuggestionMapper.map([
            ReportDiagnostic(severity: 'error', code: code, message: 'x'),
          ]);
          expect(result, hasLength(1));
          final expected = FixSuggestionMapper.kFixSuggestions[code]!;
          expect(result[0].diagnosticCode, expected.diagnosticCode);
          expect(result[0].suggestionText, expected.suggestionText);
          expect(result[0].configField, expected.configField);
          expect(result[0].targetFeature, expected.targetFeature);
        }
      }
    });

    test(
        'P2: unknown code returns generic fallback containing review phrase',
        () {
      for (int i = 0; i < 200; i++) {
        final code = randomCode(forceUnknown: true);
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(
              severity: 'error', code: code, message: 'Something went wrong.'),
        ]);
        expect(result, hasLength(1));
        expect(result[0].diagnosticCode, code);
        expect(
          result[0].suggestionText,
          anyOf(contains('Review the config'), contains('Review the feature')),
        );
        expect(result[0].configField, isNull);
      }
    });

    test('P3: unknown code with feature gets feature-specific fallback', () {
      for (int i = 0; i < 100; i++) {
        final code = randomCode(forceUnknown: true);
        final feat = String.fromCharCodes(
            List.generate(rng.nextInt(6) + 3, (_) => rng.nextInt(26) + 97));
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(
              severity: 'error',
              code: code,
              message: 'Error',
              feature: feat),
        ]);
        expect(result, hasLength(1));
        expect(result[0].suggestionText, contains('Review the feature'));
        expect(result[0].suggestionText, contains(feat));
        expect(result[0].targetFeature, feat);
      }
    });

    test('P4: mixed known+unknown list — output count matches input', () {
      for (int i = 0; i < 100; i++) {
        final n = rng.nextInt(15) + 1;
        final diags = List.generate(n, (_) {
          return ReportDiagnostic(
            severity: 'error',
            code: randomCode(forceUnknown: rng.nextBool()),
            message: 'msg',
          );
        });
        final result = FixSuggestionMapper.map(diags);
        expect(result, hasLength(n));
        for (int j = 0; j < n; j++) {
          expect(result[j].diagnosticCode, diags[j].code);
        }
      }
    });

    test('P5: every known key in kFixSuggestions maps to itself', () {
      for (final code in knownCodes()) {
        final result = FixSuggestionMapper.map([
          ReportDiagnostic(severity: 'error', code: code, message: 'x'),
        ]);
        expect(result, hasLength(1));
        expect(result[0].diagnosticCode, code);
        expect(result[0].configField,
            FixSuggestionMapper.kFixSuggestions[code]!.configField);
        expect(result[0].targetFeature,
            FixSuggestionMapper.kFixSuggestions[code]!.targetFeature);
      }
    });

    test('P6: empty list maps to empty list', () {
      expect(FixSuggestionMapper.map([]), isEmpty);
    });
  });
}
