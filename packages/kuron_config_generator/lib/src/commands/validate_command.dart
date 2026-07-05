// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/command_runner.dart';

import '../validation/validation_orchestrator.dart';

/// Validate a generated config using the runtime validator.
class ValidateCommand extends Command<void> {
  ValidateCommand() {
    argParser
      ..addOption(
        'workdir',
        abbr: 'w',
        mandatory: true,
        help: 'Work directory containing generated config and fixtures.',
      )
      ..addOption(
        'format',
        abbr: 'f',
        help: 'Report format (json or markdown).',
        allowed: ['json', 'markdown'],
        defaultsTo: 'markdown',
      );
  }

  @override
  String get name => 'validate-generated';

  @override
  String get description =>
      'Validate a generated config using the runtime validator.';

  @override
  Future<void> run() async {
    final workdir = argResults?['workdir'] as String;

    // Find config JSON file in workdir
    final dir = Directory(workdir);
    if (!await dir.exists()) {
      stderr.writeln('Error: Work directory not found: $workdir');
      exit(1);
    }

    final configFiles = dir
        .listSync()
        .where((e) =>
            e is File &&
            e.path.endsWith('-config.json') &&
            !e.path.endsWith('.original.json'))
        .toList();

    if (configFiles.isEmpty) {
      stderr.writeln('Error: No config file found in $workdir');
      exit(1);
    }

    final configPath = (configFiles.first as File).path;
    final orchestrator = ValidationOrchestrator();
    final parsed = await orchestrator.runValidator(configPath);

    if (parsed == null) {
      stderr.writeln('Error: Validation failed or could not parse report.');
      exit(1);
    }

    // Display summary
    print('[${parsed.overallStatus}] ${parsed.sourceId}');
    if (parsed.featureStatuses.isNotEmpty) {
      for (final e in parsed.featureStatuses.entries) {
        print('  ${e.key}: ${e.value}');
      }
    }

    if (parsed.diagnostics.isNotEmpty) {
      print('\nDiagnostics:');
      for (final d in parsed.diagnostics) {
        print('  [${d.severity}] ${d.code}: ${d.message}');
      }
    }

    if (parsed.overallStatus == 'compatible') {
      print('\n✓ Config is valid!');
    } else {
      exit(1);
    }
  }
}
