import 'package:test/test.dart';
import 'package:kuron_config_generator/src/commands/generate_command.dart';
import 'package:kuron_config_generator/src/commands/discover_command.dart';
import 'package:kuron_config_generator/src/commands/validate_command.dart';

void main() {
  group('CLI commands', () {
    test('GenerateCommand has expected name and description', () {
      final cmd = GenerateCommand();
      expect(cmd.name, 'generate');
      expect(cmd.description, contains('Generate'));
    });

    test('DiscoverCommand has expected name and description', () {
      final cmd = DiscoverCommand();
      expect(cmd.name, 'discover');
      expect(cmd.description, contains('Discover'));
    });

    test('ValidateCommand has expected name and description', () {
      final cmd = ValidateCommand();
      expect(cmd.name, 'validate-generated');
      expect(cmd.description, contains('Validate'));
    });

    test('GenerateCommand requires url or interactive flag', () {
      final cmd = GenerateCommand();
      expect(cmd.argParser.options, contains('url'));
      expect(cmd.argParser.options, contains('interactive'));
    });
  });
}
