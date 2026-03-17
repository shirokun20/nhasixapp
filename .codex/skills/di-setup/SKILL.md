---
name: di-setup
description: Setup Dependency Injection with GetIt for NhasixApp following Clean Architecture
license: MIT
compatibility: opencode
metadata:
  category: architecture
  framework: flutter
  project: nhasixapp
---

# Dependency Injection Skill for NhasixApp

This skill guides you through setting up DI with GetIt following Clean Architecture principles.

## GetIt Configuration Structure

```
lib/core/di/
├── injection.dart          # Main GetIt configuration
└── modules/               # Feature-specific modules
    ├── auth_module.dart
    ├── user_module.dart
    └── ...
```

## Basic Setup

### Main Injection File

```dart
// core/di/injection.dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // External dependencies
  _registerExternal();
  
  // Data sources
  _registerDataSources();
  
  // Repositories
  _registerRepositories();
  
  // Use cases
  _registerUseCases();
  
  // BLoCs/Cubits
  _registerBlocs();
}

void _registerExternal() {
  // Dio for HTTP
  getIt.registerLazySingleton<Dio>(() => Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 30),
  )));
  
  // Connectivity
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt()),
  );
}

void _registerDataSources() {
  // Remote
  getIt.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(dio: getIt()),
  );
  
  // Local
  getIt.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(sharedPreferences: getIt()),
  );
}

void _registerRepositories() {
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );
}

void _registerUseCases() {
  getIt.registerFactory(() => GetUserUseCase(getIt()));
  getIt.registerFactory(() => UpdateUserUseCase(getIt()));
}

void _registerBlocs() {
  getIt.registerFactory(() => UserCubit(getUserUseCase: getIt()));
  getIt.registerFactory(() => UserBloc(
    getUserUseCase: getIt(),
    updateUserUseCase: getIt(),
  ));
}
```

## Registration Types

### LazySingleton
Use for dependencies that should be created once and reused:
- Repositories
- Data sources
- Services
- External libraries (Dio, etc.)

```dart
getIt.registerLazySingleton<UserRepository>(
  () => UserRepositoryImpl(...),
);
```

### Singleton
Use when you need immediate initialization:
- Configuration
- Platform channels

```dart
getIt.registerSingleton<Config>(Config.load());
```

### Factory
Use for dependencies that need fresh instances:
- Use cases
- BLoCs/Cubits
- ViewModels

```dart
getIt.registerFactory(() => GetUserUseCase(getIt()));
```

## Feature Module Pattern

For large projects, split into modules:

```dart
// core/di/modules/user_module.dart
abstract class UserModule {
  static void init(GetIt getIt) {
    // Data sources
    getIt.registerLazySingleton<UserRemoteDataSource>(
      () => UserRemoteDataSourceImpl(dio: getIt()),
    );
    
    // Repository
    getIt.registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(
        remoteDataSource: getIt(),
        networkInfo: getIt(),
      ),
    );
    
    // Use cases
    getIt.registerFactory(() => GetUserUseCase(getIt()));
    getIt.registerFactory(() => UpdateUserUseCase(getIt()));
    
    // BLoC
    getIt.registerFactory(() => UserBloc(
      getUserUseCase: getIt(),
      updateUserUseCase: getIt(),
    ));
  }
}
```

Update main injection:

```dart
// core/di/injection.dart
Future<void> configureDependencies() async {
  _registerExternal();
  
  // Feature modules
  UserModule.init(getIt);
  AuthModule.init(getIt);
  // ... more modules
}
```

## Using Dependencies

### In UI

```dart
class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<UserCubit>(),
      child: const UserView(),
    );
  }
}
```

### In Tests

```dart
void main() {
  setUp(() {
    getIt.registerFactory<UserRepository>(
      () => MockUserRepository(),
    );
  });

  tearDown(() {
    getIt.reset();
  });

  test('should get user', () async {
    final useCase = getIt<GetUserUseCase>();
    // Test...
  });
}
```

## Common Patterns

### Environment-Specific Configuration

```dart
Future<void> configureDependencies({String env = 'dev'}) async {
  if (env == 'prod') {
    getIt.registerLazySingleton<Dio>(() => Dio(BaseOptions(
      baseUrl: 'https://api.prod.com',
    )));
  } else {
    getIt.registerLazySingleton<Dio>(() => Dio(BaseOptions(
      baseUrl: 'https://api.dev.com',
    )));
  }
  
  // ... rest of configuration
}
```

### Async Initialization

```dart
Future<void> configureDependencies() async {
  // Async initialization
  final prefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => prefs);
  
  // ... rest of configuration
}
```

### Named Registrations (if needed)

```dart
// Register with name
getIt.registerLazySingleton<Dio>(
  () => Dio(BaseOptions(baseUrl: 'https://api1.com')),
  instanceName: 'api1',
);

getIt.registerLazySingleton<Dio>(
  () => Dio(BaseOptions(baseUrl: 'https://api2.com')),
  instanceName: 'api2',
);

// Retrieve by name
final api1 = getIt<Dio>(instanceName: 'api1');
```

## Best Practices

1. **Order Matters**: Register dependencies in order (external -> data -> domain -> presentation)
2. **Use LazySingleton**: For most dependencies to avoid startup overhead
3. **Use Factory**: For BLoCs and use cases that need fresh state
4. **One GetIt Instance**: Use the global `getIt` throughout the app
5. **Reset in Tests**: Always reset GetIt between tests
6. **Abstract Dependencies**: Register interfaces, not implementations

## Verification Checklist

- [ ] All external dependencies registered (Dio, DB, etc.)
- [ ] All data sources registered
- [ ] All repositories registered
- [ ] All use cases registered
- [ ] All BLoCs/Cubits registered
- [ ] No circular dependencies
- [ ] Can resolve all types without errors
- [ ] Tests can mock dependencies

## Common Mistakes

- ❌ Registering implementations instead of interfaces
- ❌ Wrong registration type (singleton vs factory)
- ❌ Missing dependencies in chain
- ❌ Not resetting GetIt in tests
- ❌ Registering in wrong order

## When to Use

- Setting up new projects
- Adding new features
- Refactoring architecture
- Debugging DI issues
