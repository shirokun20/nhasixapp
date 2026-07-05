// ignore_for_file: avoid_print

import 'dart:io';

import 'report_parser.dart';
import 'fix_suggestion.dart';
import 'validator_runner.dart';

/// Orchestrates the validation lifecycle: run validator, parse report,
/// display results, and manage the interactive revalidation loop.
class ValidationOrchestrator {
  /// Run a single validation cycle on [configPath].
  /// Returns parsed report on success, null if validator unavailable or
  /// report cannot be parsed.
  Future<ParsedReport?> runValidator(String configPath) async {
    final jsonString = await ValidatorRunner.run(configPath);
    if (jsonString == null) return null;

    try {
      return ReportParser.parse(jsonString);
    } on FormatException catch (e) {
      stderr.writeln('Warning: Failed to parse validation report: $e');
      return null;
    }
  }

  /// Run the full interactive validation loop.
  ///
  /// Creates a backup of the config, then iterates up to 20 times,
  /// prompting the user to edit and revalidate after each run.
  ///
  /// [reportFormat] controls display format (text/json/markdown).
  /// [showAllSuggestions] shows fix suggestions even when compatible.
  Future<void> runValidationLoop({
    required String configPath,
    String reportFormat = 'text',
    bool showAllSuggestions = false,
  }) async {
    // R8.1–R8.4: Backup on first entry only
    await _createBackup(configPath);

    for (var i = 0; i < 20; i++) {
      // R4.6: Check config file still exists
      if (!File(configPath).existsSync()) {
        stderr.writeln(
          'Error: Config file deleted or unreadable — exiting validation loop.',
        );
        break;
      }

      final parsed = await runValidator(configPath);
      if (parsed == null) {
        // Validator fatal error — warning already printed by runValidator
        stderr.writeln(
          'Validation loop ended due to validator error.',
        );
        break;
      }

      final suggestions = FixSuggestionMapper.map(parsed.diagnostics);

      // Display summary
      print('[${parsed.overallStatus}] ${parsed.sourceId}');
      if (parsed.featureStatuses.isNotEmpty) {
        for (final e in parsed.featureStatuses.entries) {
          print('  ${e.key}: ${e.value}');
        }
      }

      // Display suggestions
      if (suggestions.isNotEmpty) {
        print('\nFix suggestions:');
        for (var j = 0; j < suggestions.length; j++) {
          final s = suggestions[j];
          print('  ${j + 1}. [${s.diagnosticCode}] ${s.suggestionText}');
        }
      }

      // R4.4: Compatible → exit loop
      if (parsed.overallStatus == 'compatible') {
        print('\n✓ Config is valid!');
        break;
      }

      // R4.7: Max iterations reached
      if (i == 19) {
        print(
          'Maximum validation iterations (20) reached — exiting loop.',
        );
        break;
      }

      // R4.1–R4.3, R4.8: User prompt
      while (true) {
        stdout.write(
          'Validation found issues. Review the report above, edit the config, '
          'then press Enter to revalidate, or type \'q\' to quit: ',
        );
        final input = stdin.readLineSync()?.trim() ?? '';

        if (input.isEmpty) {
          // Enter → continue loop
          break;
        }
        if (input.toLowerCase() == 'q') {
          print('Validation loop ended. Generated config at: $configPath');
          return; // exit loop (R4.3)
        }
        // R4.8: Other input → re-prompt
      }
    }
  }

  /// Create a backup of [configPath] at `{configPath}.original.json`.
  /// Never overwrites existing backup (R8.3).
  Future<void> _createBackup(String configPath) async {
    final backupPath = '$configPath.original.json';
    final backupFile = File(backupPath);
    if (await backupFile.exists()) return; // R8.3

    try {
      await File(configPath).copy(backupPath);
    } catch (e) {
      stderr.writeln('Warning: Could not create backup: $e'); // R8.4
    }
  }
}
