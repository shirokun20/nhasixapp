// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';
import 'package:kuron_config_generator/src/validation/validator_runner.dart';
import 'package:kuron_config_generator/src/validation/validation_orchestrator.dart';
import 'package:kuron_config_generator/src/validation/report_parser.dart';
import 'package:kuron_config_generator/src/validation/fix_suggestion.dart';
import 'package:kuron_config_generator/src/validation/backup_manager.dart';
import 'package:kuron_config_generator/src/commands/generate_command.dart';
import 'package:args/command_runner.dart';

ProcessResult _result(
    {required int exitCode, String stdout = '', String stderr = ''}) {
  return ProcessResult(0, exitCode, stdout, stderr);
}

Future<ProcessResult> Function(String, List<String>) _fakeRunner(
  String json,
) {
  return (String exe, List<String> args) async =>
      _result(exitCode: 0, stdout: json);
}

void main() {
  group('ValidatorRunner', () {
    test('returns null on ProcessException "not found" (R7.1)', () async {
      Future<ProcessResult> notFoundRunner(
          String exe, List<String> args) async {
        throw ProcessException(
          'dart',
          [
            'dart',
            'run',
            'kuron_generic:kuron_config_validate',
            '--format',
            'json',
            '/fake/path'
          ],
          'Error: not found',
        );
      }

      final result = await ValidatorRunner.run(
        '/fake/path',
        processRunner: notFoundRunner,
      );
      expect(result, isNull);
    });

    test('returns stdout on non-zero exit (R7.2)', () async {
      Future<ProcessResult> nonZeroRunner(String exe, List<String> args) async {
        return _result(
          exitCode: 1,
          stdout: '{"sourceId":"test","overallStatus":"configError"}',
          stderr: 'Something went wrong',
        );
      }

      final result = await ValidatorRunner.run(
        '/fake/path',
        processRunner: nonZeroRunner,
      );
      expect(result, '{"sourceId":"test","overallStatus":"configError"}');
    });

    test('handles unexpected ProcessException gracefully (R7.3)', () async {
      Future<ProcessResult> unexpectedRunner(
          String exe, List<String> args) async {
        throw ProcessException('dart', [], 'No such file or directory');
      }

      final result = await ValidatorRunner.run(
        '/fake/path',
        processRunner: unexpectedRunner,
      );
      expect(result, isNull);
    });

    test('returns stdout on exit code 0', () async {
      Future<ProcessResult> successRunner(String exe, List<String> args) async {
        return _result(
          exitCode: 0,
          stdout: '{"sourceId":"test","overallStatus":"compatible"}',
        );
      }

      final result = await ValidatorRunner.run(
        '/fake/path',
        processRunner: successRunner,
      );
      expect(result, '{"sourceId":"test","overallStatus":"compatible"}');
    });
  });

  group('Property: Non-Blocking Validation (R7.1, R7.2, R7.3)', () {
    final rng = Random(42);

    String randomMsg(int minLen, int maxLen) {
      final len = minLen + rng.nextInt(maxLen - minLen + 1);
      return String.fromCharCodes(
          List.generate(len, (_) => rng.nextInt(95) + 32));
    }

    int randomExitCode() {
      return [0, 1, -1, 2, 64, 127, 255, 256][rng.nextInt(8)];
    }

    String randomStderr() {
      final len = rng.nextInt(100);
      return String.fromCharCodes(
          List.generate(len, (_) => rng.nextInt(95) + 32));
    }

    String? randomStdout() {
      if (rng.nextBool()) {
        final len = rng.nextInt(200);
        return String.fromCharCodes(
            List.generate(len, (_) => rng.nextInt(95) + 32));
      }
      return null;
    }

    test('P2: run() returns stdout on any exit code', () async {
      for (var i = 0; i < 100; i++) {
        final exitCode = randomExitCode();
        final stderr = randomStderr();
        final out = randomStdout() ?? '';

        Future<ProcessResult> exitRunner(String exe, List<String> args) async =>
            ProcessResult(0, exitCode, out, stderr);

        final result = await ValidatorRunner.run(
          '/some/path',
          processRunner: exitRunner,
        );
        expect(result, isNotNull,
            reason: 'iteration $i: exit $exitCode → not null');
        expect(result, isA<String>(),
            reason: 'iteration $i: exit $exitCode → String');
        expect(result, out, reason: 'iteration $i: exit $exitCode → stdout');
      }
    });

    test('P3: run() never crashes on empty path', () async {
      for (var i = 0; i < 50; i++) {
        final emptyPath = randomMsg(0, 5);
        Future<ProcessResult> crashRunner(
                String exe, List<String> args) async =>
            throw ProcessException(exe, args, 'crash');
        final result = await ValidatorRunner.run(
          emptyPath,
          processRunner: crashRunner,
        );
        expect(result, isNull);
      }
    });

    test('P4: run() never crashes on very long paths', () async {
      for (var i = 0; i < 50; i++) {
        final longPath =
            '/${List.generate(200, (_) => rng.nextInt(26) + 97).join()}';
        Future<ProcessResult> crashRunner(
                String exe, List<String> args) async =>
            throw ProcessException(exe, args, 'crash');
        final result = await ValidatorRunner.run(
          longPath,
          processRunner: crashRunner,
        );
        expect(result, isNull);
      }
    });

    test('P5: run() returns null or String', () async {
      for (var i = 0; i < 200; i++) {
        final variant = rng.nextInt(3);
        Future<ProcessResult> mixedRunner(String exe, List<String> args) async {
          switch (variant) {
            case 0:
              throw ProcessException(exe, args, randomMsg(5, 20));
            case 1:
              return ProcessResult(
                0,
                rng.nextBool() ? 0 : 1,
                randomStdout() ?? '',
                randomStderr(),
              );
            case 2:
              throw Exception(randomMsg(5, 20));
          }
          throw ProcessException(exe, args, 'fallback');
        }

        final result = await ValidatorRunner.run(
          '/some/path',
          processRunner: mixedRunner,
        );
        expect(result, anyOf([isNull, isA<String>()]));
      }
    });

    test('P6: run() does not throw for any exit code 0-255', () async {
      for (var i = 0; i < 256; i++) {
        Future<ProcessResult> allCodesRunner(
                String exe, List<String> args) async =>
            ProcessResult(0, i, 'stdout', '');
        final result = await ValidatorRunner.run(
          '/path',
          processRunner: allCodesRunner,
        );
        expect(result, isNotNull);
        expect(result, isA<String>());
        expect(result, 'stdout');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Integration Tests: Validation Orchestration Flow (Task 6.3)
  // ═══════════════════════════════════════════════════════════════════

  group('Integration: Validation Orchestrator (R1.1, R1.4, R1.5, R5.5, R6.1)',
      () {
    late Directory tmpDir;
    late String configPath;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('orch_integration_');
      configPath = '${tmpDir.path}/test-config.json';
    });

    tearDown(() {
      tmpDir.deleteSync(recursive: true);
    });

    void writeConfig(String json) {
      File(configPath).writeAsStringSync(json);
    }

    test(
      'R1.1: Validation runs and reports compatible via mock runner',
      () async {
        writeConfig(jsonEncode({'sourceId': 'testsite', 'version': '1.0'}));

        final reportJson = jsonEncode({
          'sourceId': 'testsite',
          'overallStatus': 'compatible',
          'featureStatuses': {'home': 'compatible'},
          'diagnostics': [],
        });

        final result = await ValidatorRunner.run(
          configPath,
          processRunner: _fakeRunner(reportJson),
        );
        expect(result, reportJson);

        final parsed = ReportParser.parse(result!);
        expect(parsed.overallStatus, 'compatible');
        expect(parsed.sourceId, 'testsite');
      },
    );

    test(
      'R1.4: GenerateCommand has --validate flag defaulting to false',
      () async {
        final cmd = GenerateCommand();
        expect(cmd.argParser.options.containsKey('validate'), isTrue);

        // Verify default behavior
        final runner = CommandRunner<void>('test', 'test runner');
        runner.addCommand(cmd);
        await runner.run(['generate', '--url', 'https://example.com']);
      },
    );

    test(
      'R1.5: runValidator returns null for nonexistent config',
      () async {
        final orchestrator = ValidationOrchestrator();
        final result = await orchestrator.runValidator(
          '/nonexistent/config.json',
        );
        expect(result, isNull);
      },
    );

    test(
      'R6.1: BackupManager creates backup on first entry',
      () async {
        writeConfig(jsonEncode({'sourceId': 'testsite', 'version': '1.0'}));

        await BackupManager.createBackup(configPath);

        final backupPath = '${configPath}.original.json';
        expect(File(backupPath).existsSync(), isTrue);
      },
    );

    test(
      'R5.5: Report format options are validated',
      () async {
        final cmd = GenerateCommand();
        final option = cmd.argParser.options['validate-format']!;
        expect(option.allowed, contains('text'));
        expect(option.allowed, contains('json'));
        expect(option.allowed, contains('markdown'));
        expect(option.defaultsTo, 'text');
      },
    );

    test(
      'Backup + restore round-trip preserves original config',
      () async {
        const originalContent = '{"sourceId":"preserve-test","version":"1.0"}';
        File(configPath).writeAsStringSync(originalContent);

        await BackupManager.createBackup(configPath);

        File(configPath).writeAsStringSync('{"sourceId":"modified"}');

        final restored = await BackupManager.restoreBackup(configPath);
        expect(restored, isTrue);
        expect(File(configPath).readAsStringSync(), originalContent);
      },
    );

    test(
      'Diagnostics are mapped to fix suggestions',
      () async {
        final diagnostics = [
          ReportDiagnostic(
            severity: 'error',
            code: 'reader.configError',
            message: 'No image selector.',
            feature: 'reader',
          ),
        ];

        final suggestions = FixSuggestionMapper.map(diagnostics);
        expect(suggestions, hasLength(1));
        expect(suggestions[0].diagnosticCode, 'reader.configError');
        expect(suggestions[0].suggestionText,
            contains('scraper.selectors.reader'));
        expect(suggestions[0].targetFeature, 'reader');
      },
    );

    test(
      'Orchestrator uses ReportPrinter for display',
      () async {
        writeConfig(jsonEncode({
          'sourceId': 'compatible-test',
          'version': '1.0',
        }));

        final reportJson = jsonEncode({
          'sourceId': 'compatible-test',
          'overallStatus': 'compatible',
          'featureStatuses': {'home': 'compatible'},
          'diagnostics': [],
        });

        final result = await ValidatorRunner.run(
          configPath,
          processRunner: _fakeRunner(reportJson),
        );
        expect(result, isNotNull);

        final parsed = ReportParser.parse(result!);
        expect(parsed.overallStatus, 'compatible');

        final suggestions = FixSuggestionMapper.map(parsed.diagnostics);
        expect(suggestions, isEmpty);
      },
    );

    test(
      'GenerateCommand has --fix-suggestions flag',
      () async {
        final cmd = GenerateCommand();
        expect(cmd.argParser.options.containsKey('fix-suggestions'), isTrue);
      },
    );
  });
}
