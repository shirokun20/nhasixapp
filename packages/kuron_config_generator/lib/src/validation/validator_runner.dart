import 'dart:io';

class ValidatorRunner {
  /// Run the validator CLI via `dart run kuron_generic:kuron_config_validate`.
  /// Returns stdout content on success, null if validator unavailable or crashes.
  static Future<String?> run(String configPath) async {
    try {
      final result = await Process.run(
        'dart',
        [
          'run',
          'kuron_generic:kuron_config_validate',
          '--format',
          'json',
          configPath,
        ],
      );
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
