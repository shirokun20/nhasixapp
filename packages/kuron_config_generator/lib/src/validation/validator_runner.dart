import 'dart:io';

class ValidatorRunner {
  /// Run the validator CLI via `dart run kuron_generic:kuron_config_validate`.
  /// Returns stdout content on success, null if validator unavailable or crashes.
  ///
  /// [processRunner] is injected for testing — defaults to [Process.run].
  static Future<String?> run(
    String configPath, {
    Future<ProcessResult> Function(String executable, List<String> arguments)?
        processRunner,
  }) async {
    try {
      final args = [
        'run',
        'kuron_generic:kuron_config_validate',
        '--format',
        'json',
        configPath,
      ];
      final result = processRunner != null
          ? await processRunner('dart', args)
          : await Process.run('dart', args);
      if (result.exitCode != 0 && (result.stderr as String).isNotEmpty) {
        stderr.writeln(
          'Warning: Validator exited with code ${result.exitCode}: '
          '${result.stderr}',
        );
      }
      return result.stdout as String?;
    } on ProcessException catch (e) {
      if (e.message.contains('not found')) {
        stderr.writeln(
          'Warning: Validator not available — install kuron_generic '
          'to use --validate.',
        );
      } else {
        stderr.writeln('Warning: Validator error: $e');
      }
      return null;
    } catch (e) {
      stderr.writeln('Warning: Validator error: $e');
      return null;
    }
  }
}
