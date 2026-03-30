# Dependency Injection Setup

Guide for setting up DI with GetIt following Clean Architecture.

## Structure
```
lib/core/di/
├── service_locator.dart     # Main GetIt configuration
└── modules/                 # Feature-specific modules (optional)
```

## Registration Types

| Type | When to Use | Example |
|------|-------------|---------|
| `registerLazySingleton` | Repositories, DataSources, Services, Dio | Created once on first use |
| `registerSingleton` | Config, Platform Channels | Created immediately |
| `registerFactory` | UseCases, BLoCs/Cubits | Fresh instance every time |

## Registration Order (IMPORTANT)

```dart
Future<void> configureDependencies() async {
  _registerExternal();      // Dio, SharedPreferences, etc.
  _registerDataSources();   // Remote & Local data sources
  _registerRepositories();  // Repository implementations
  _registerUseCases();      // Use cases
  _registerBlocs();         // BLoCs and Cubits
}
```

## Example Registration

```dart
// External
getIt.registerLazySingleton<Dio>(() => Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
  connectTimeout: const Duration(seconds: 30),
)));

// DataSource
getIt.registerLazySingleton<UserRemoteDataSource>(
  () => UserRemoteDataSourceImpl(dio: getIt()),
);

// Repository (register interface, not implementation)
getIt.registerLazySingleton<UserRepository>(
  () => UserRepositoryImpl(remoteDataSource: getIt(), networkInfo: getIt()),
);

// UseCase
getIt.registerFactory(() => GetUserUseCase(getIt()));

// Cubit
getIt.registerFactory(() => UserCubit(getUserUseCase: getIt()));
```

## Using in UI

```dart
BlocProvider(
  create: (context) => getIt<UserCubit>()..loadUser(userId),
  child: const UserView(),
)
```

## Using in Tests

```dart
setUp(() {
  getIt.registerFactory<UserRepository>(() => MockUserRepository());
});
tearDown(() => getIt.reset());
```

## Feature Module Pattern (large projects)

```dart
abstract class UserModule {
  static void init(GetIt getIt) {
    getIt.registerLazySingleton<UserRemoteDataSource>(() => UserRemoteDataSourceImpl(dio: getIt()));
    getIt.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(remoteDataSource: getIt()));
    getIt.registerFactory(() => GetUserUseCase(getIt()));
    getIt.registerFactory(() => UserCubit(getUserUseCase: getIt()));
  }
}
```

## Common Mistakes
- Registering implementations instead of interfaces
- Wrong type (singleton vs factory for BLoCs — always factory!)
- Missing dependencies in chain
- Not resetting GetIt in tests
- Registering in wrong order (dependency before its own dependency)
