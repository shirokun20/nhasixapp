import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';
import 'package:kuron_config_generator/src/validation/validator_runner.dart';

ProcessResult _result({required int exitCode, String stdout = '', String stderr = ''}) {
  return ProcessResult(0, exitCode, stdout, stderr);
}

void main() {
  group('ValidatorRunner', () {
    // ── R7.1: ProcessException "not found" → returns null ─────────────
    test('returns null on ProcessException "not found" (R7.1)', () async {
      Future<ProcessResult> notFoundRunner(String exe, List<String> args) async {
        throw ProcessException(
          'dart',
          ['dart', 'run', 'kuron_generic:kuron_config_validate', '--format', 'json', '/fake/path'],
          'Error: not found',
        );
      }

      final result = await ValidatorRunner.run(
        '/fake/path',
        processRunner: notFoundRunner,
      );
      expect(result, isNull);
    });

    // ── R7.2: Non-zero exit → still returns stdout ────────────────────
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

    // ── R7.3: Handles unexpected ProcessException gracefully → null ───
    test('handles unexpected ProcessException gracefully (R7.3)', () async {
      Future<ProcessResult> unexpectedRunner(String exe, List<String> args) async {
        throw ProcessException('dart', [], 'No such file or directory');
      }

      final result = await ValidatorRunner.run(
        '/fake/path',
        processRunner: unexpectedRunner,
      );
      expect(result, isNull);
    });

    // ── Happy path: exit code 0 → returns stdout ──────────────────────
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

  // ── Property test: Non-Blocking Validation ─────────────────────────
  //
  // **Validates: Requirements 7.1, 7.2, 7.3**
  // For any ProcessException or non-zero exit variant,
  // ValidatorRunner.run() never throws and returns null OR String.

  group('Property: Non-Blocking Validation (R7.1, R7.2, R7.3)', () {
    final rng = Random(42); // seeded for reproducibility

    /// Generate a random string of printable ASCII for error messages.
    String randomMsg(int minLen, int maxLen) {
      final len = minLen + rng.nextInt(maxLen - minLen + 1);
      return String.fromCharCodes(List.generate(
          len, (_) => rng.nextInt(95) + 32)); // space through ~
    }

    /// Generate a random exit code (0, 1, or random non-zero).
    int randomExitCode() {
      return [0, 1, -1, 2, 64, 127, 255, 256][rng.nextInt(8)];
    }

    /// Generate random stderr content (empty, short, long, binary-ish).
    String randomStderr() {
      final choice = rng.nextInt(4);
      switch (choice) {
        case 0:
          return '';
        case 1:
          return randomMsg(5, 30);
        case 2:
          return randomMsg(100, 500);
        default:
          // binary-ish noise including non-printables
          return String.fromCharCodes(
              List.generate(rng.nextInt(20) + 1, (_) => rng.nextInt(256)));
      }
    }

    /// Generate random stdout content (null-ish or JSON string).
    String? randomStdout() {
      if (rng.nextBool()) return '';
      if (rng.nextBool()) return 'not json at all';
      if (rng.nextBool()) {
        return '{"sourceId":"test","overallStatus":"${['compatible', 'configError', 'partiallyCompatible'][rng.nextInt(3)]}"}';
      }
      return '   ';
    }

    test(
        'P1: no exception propagates from run() for any ProcessException variant',
        () async {
      for (var i = 0; i < 200; i++) {
        final exeMsg = [
          'not found', 'No such file or directory', 'Permission denied',
          'broken pipe', 'connection refused', 'unknown error', ''
        ][rng.nextInt(7)];
        final processException = ProcessException(
          'dart',
          ['run', 'kuron_generic:kuron_config_validate', '--format', 'json', '/some/path'],
          exeMsg,
        );

        Future<ProcessResult> throwingRunner(
                String exe, List<String> args) async =>
            throw processException;

        // run() must never throw; it always catches and returns null
        final result = await ValidatorRunner.run(
          '/some/path',
          processRunner: throwingRunner,
        );
        expect(result, isNull, reason: 'iteration $i: ProcessException → null');
      }
    });

    test(
        'P2: no exception propagates from run() for any non-zero exit variant',
        () async {
      for (var i = 0; i < 200; i++) {
        final exitCode = randomExitCode();
        final stderr = randomStderr();
        // Ensure stdout is non-null String for ProcessResult
        final out = randomStdout() ?? '';

        Future<ProcessResult> exitRunner(
                String exe, List<String> args) async =>
            ProcessResult(0, exitCode, out, stderr);

        // run() must never throw; returns stdout regardless of exit code
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

    test(
        'P5: run() returns either null (process error) or String (stdout available)',
        () async {
      for (var i = 0; i < 200; i++) {
        final variant = rng.nextInt(3);
        Future<ProcessResult> mixedRunner(
                String exe, List<String> args) async {
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
              throw Exception(randomMsg(5, 20)); // generic exception
          }
          throw ProcessException(exe, args, 'fallback');
        }

        final result = await ValidatorRunner.run(
          '/some/path',
          processRunner: mixedRunner,
        );
        // Invariant: run() never throws — verified by reaching this line.
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
}
