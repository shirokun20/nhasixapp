// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    print('❌ Error: Please provide a feature name.');
    print('Usage: dart scripts/create_feature.dart [feature_name]');
    exit(1);
  }

  final featureName = arguments[0].toLowerCase();
  final baseDir = 'lib/features/$featureName';

  print('🚀 Scaffolding Clean Architecture for feature: "$featureName"...\n');

  final directories = [
    // Domain Layer
    '$baseDir/domain/entities',
    '$baseDir/domain/repositories',
    '$baseDir/domain/usecases',

    // Data Layer
    '$baseDir/data/datasources/local',
    '$baseDir/data/datasources/remote',
    '$baseDir/data/models',
    '$baseDir/data/repositories',

    // Presentation Layer
    '$baseDir/presentation/bloc',
    '$baseDir/presentation/pages',
    '$baseDir/presentation/widgets',
  ];

  for (final dirPath in directories) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      print('  ✅ Created: $dirPath');

      // Create a .gitkeep file to ensure git tracks empty folders
      File('${dir.path}/.gitkeep').createSync();
    } else {
      print('  ⚠️ Exists: $dirPath');
    }
  }

  print('\n✨ Feature "$featureName" created successfully!');
  print('👉 Location: lib/features/$featureName');
}
