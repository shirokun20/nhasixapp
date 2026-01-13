---
name: flutter-dev
description: Panduan development Flutter untuk NhasixApp termasuk build commands, testing, dan konvensi coding
license: MIT
compatibility: opencode
metadata:
  audience: developers
  framework: flutter
---

## Flutter Development Guide untuk NhasixApp

### Core Commands

| Command | Deskripsi |
|---------|-----------|
| `flutter clean && flutter pub get` | Bersihkan dan download dependencies |
| `flutter run --debug` | Run app dalam mode debug |
| `flutter build apk --release` | Build APK release |
| `flutter build ipa` | Build iOS release |
| `flutter test` | Jalankan unit tests |
| `flutter analyze` | Static analysis |
| `dart run build_runner build` | Generate code (freezed, json_serializable) |

### Build Runner

Untuk generate code otomatis (models, freezed classes):
```bash
dart run build_runner build --delete-conflicting-outputs
```

Untuk watch mode:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Testing

```bash
# Run semua tests
flutter test

# Run test spesifik
flutter test test/path/to/test_file.dart

# Run dengan coverage
flutter test --coverage
```

### Konvensi Coding

#### File Naming
- Gunakan `snake_case` untuk nama file: `user_repository.dart`
- Gunakan `PascalCase` untuk nama class: `UserRepository`
- Gunakan `camelCase` untuk variabel: `userName`

#### Imports
Urutan import yang benar:
1. Dart SDK imports
2. Flutter imports
3. Package imports (external)
4. Project imports (relative)

Contoh:
```dart
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/user.dart';
```

#### Logging
Gunakan `logger` package, BUKAN `print` atau `debugPrint`:
```dart
import 'package:logger/logger.dart';

final logger = Logger();

// Levels: .t (trace), .d (debug), .i (info), .w (warning), .e (error), .f (fatal)
logger.d('Debug message');
logger.e('Error message', error: exception, stackTrace: stackTrace);
```

### Assets

- Kompres gambar < 200KB
- Gunakan WebP format jika memungkinkan
- Sediakan multi-resolution (1x, 2x, 3x)
- Deklarasikan di `pubspec.yaml`

### UI/UX Best Practices

- Gunakan `MediaQuery` untuk responsive layout
- Gunakan Theme untuk konsistensi warna/style
- Tambahkan semantic labels untuk accessibility
- Implementasikan haptic feedback untuk interaksi penting
