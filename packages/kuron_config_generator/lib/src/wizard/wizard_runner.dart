import 'dart:io';
import '../models/wizard_question.dart';

/// Runs the interactive wizard and collects answers.
class WizardRunner {
  WizardRunner({required this.flow});

  final WizardFlow flow;

  /// Run the wizard interactively via stdin/stdout.
  Future<Map<String, String?>> run() async {
    stdout.writeln('=== Kuron Config Generator - Interactive Mode ===\n');

    for (final section in flow.sections.entries) {
      stdout.writeln('--- ${_titleCase(section.key)} ---');

      for (final question in section.value) {
        await _askQuestion(question);
      }
      stdout.writeln();
    }

    return flow.answers;
  }

  Future<void> _askQuestion(WizardQuestion question) async {
    while (true) {
      _printPrompt(question);
      final input = stdin.readLineSync()?.trim() ?? '';

      // Handle empty input
      if (input.isEmpty) {
        if (question.defaultValue != null) {
          question.answer = question.defaultValue;
          break;
        }
        if (!question.isRequired) {
          question.answer = null;
          break;
        }
        stdout.writeln('  ⚠ This field is required.');
        continue;
      }

      // Validate
      if (question.validator != null) {
        final error = question.validator!(input);
        if (error != null) {
          stdout.writeln('  ⚠ $error');
          continue;
        }
      }

      // Type-specific validation
      if (question.type == QuestionType.choice) {
        if (!question.choices!.contains(input)) {
          stdout.writeln('  ⚠ Must be one of: ${question.choices!.join(", ")}');
          continue;
        }
      }

      question.answer = input;
      break;
    }
  }

  void _printPrompt(WizardQuestion question) {
    final buffer = StringBuffer('  ${question.prompt}');

    if (question.type == QuestionType.choice && question.choices != null) {
      buffer.write(' [${question.choices!.join("/")}]');
    } else if (question.type == QuestionType.yesNo) {
      buffer.write(' [y/n]');
    }

    if (question.defaultValue != null) {
      buffer.write(' (default: ${question.defaultValue})');
    }

    if (!question.isRequired) {
      buffer.write(' (optional)');
    }

    buffer.write('\n  > ');
    stdout.write(buffer.toString());
  }

  String _titleCase(String input) {
    return input
        .split(RegExp(r'(?=[A-Z])'))
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
