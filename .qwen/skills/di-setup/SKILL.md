# Dependency Injection Setup Skill

## 📦 Overview

This project uses **GetIt** (v9.2.0) for Dependency Injection (DI) following the **Service Locator** pattern. All DI configuration is centralized in `lib/core/di/service_locator.dart`.

---

## 🏗️ DI Architecture

### Registration Order (CRITICAL)

Dependencies MUST be registered in this order:

```
1. External Instances (Logger, SharedPreferences, Database)
2. Services (stateless, no Flutter dependencies)
3. Data Sources (remote, local)
4. Repositories (implement domain interfaces)
5. Use Cases (domain business logic)
6. Cubits/BLoCs (presentation state)
7. Singletons that depend on above (Dio, HttpClient)
```

### Why Order Matters

GetIt resolves dependencies at runtime. If `A` depends on `B`, then `B` must be registered BEFORE `A`.

```dart
// ❌ WRONG - Will fail if DnsResolver not registered before Dio
getIt.registerSingleton<Dio>(HttpClientManager.initializeHttpClient(
  dnsResolver: getIt<DnsResolver>(), // Error if not registered yet
));

// ✅ CORRECT - Register DnsResolver first
getIt.registerLazySingleton<DnsResolver>(() => DnsResolver(
  settingsService: getIt<DnsSettingsService>(),
));

getIt.registerSingleton<Dio>(HttpClientManager.initializeHttpClient(
  dnsResolver: getIt<DnsResolver>(), // Now it works
));
```

---

## 📝 Service Locator Structure

```dart
// lib/core/di/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

final getIt = GetIt.instance;

/// Configure all dependencies
/// Call this in main() before runApp()
Future<void> configureDependencies() async {
  // ============================================
  // 1. EXTERNAL INSTANCES (Flutter SDK packages)
  // ============================================
  
  // Logger
  getIt.registerLazySingleton<Logger>(() => Logger(
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      ));

  // SharedPreferences
  getIt.registerLazySingleton<SharedPreferences>(
    () => SharedPreferences.getInstance(),
  );

  // Secure Storage
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // ============================================
  // 2. CORE SERVICES
  // ============================================

  // DNS Settings Service (registered early for DNS resolver)
  getIt.registerLazySingleton<DnsSettingsService>(() => DnsSettingsService(
        prefs: getIt<SharedPreferences>(),
        logger: getIt<Logger>(),
      ));

  // DNS Resolver
  getIt.registerLazySingleton<DnsResolver>(() => DnsResolver(
        settingsService: getIt<DnsSettingsService>(),
        logger: getIt<Logger>(),
      ));

  // HTTP Client (Dio) - EAGER singleton (not lazy)
  // Prevents circular dependency issues during re-entrant resolution
  getIt.registerSingleton<Dio>(HttpClientManager.initializeHttpClient(
    logger: getIt<Logger>(),
    dnsResolver: getIt<DnsResolver>(),
  ));

  // Remote Config Service
  getIt.registerLazySingleton<RemoteConfigService>(() => RemoteConfigService(
        dio: getIt<Dio>(),
        logger: getIt<Logger>(),
        prefs: getIt<SharedPreferences>(),
      ));

  // Cache Manager
  getIt.registerLazySingleton<CacheManager>(() => DefaultCacheManager());

  // ============================================
  // 3. DATA SOURCES
  // ============================================

  // Example: Comic Remote Data Source
  getIt.registerLazySingleton<ComicRemoteDataSource>(
    () => ComicRemoteDataSourceImpl(
      dio: getIt<Dio>(),
      remoteConfig: getIt<RemoteConfigService>(),
    ),
  );

  // Example: Comic Local Data Source
  getIt.registerLazySingleton<ComicLocalDataSource>(
    () => ComicLocalDataSourceImpl(
      database: getIt<Database>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );

  // ============================================
  // 4. REPOSITORIES
  // ============================================

  // Repository implementations
  getIt.registerLazySingleton<ComicRepository>(
    () => ComicRepositoryImpl(
      remoteDataSource: getIt<ComicRemoteDataSource>(),
      localDataSource: getIt<ComicLocalDataSource>(),
    ),
  );

  // ============================================
  // 5. USE CASES
  // ============================================

  getIt.registerLazySingleton<GetComics>(
    () => GetComics(getIt<ComicRepository>()),
  );

  getIt.registerLazySingleton<AddToFavorites>(
    () => AddToFavorites(getIt<ComicRepository>()),
  );

  // ============================================
  // 6. CUBITS/BLoCs
  // ============================================

  // Factory: New instance each time (for screen-scoped cubits)
  getIt.registerFactory<ComicCubit>(
    () => ComicCubit(
      getComics: getIt<GetComics>(),
      logger: getIt<Logger>(),
    ),
  );

  getIt.registerFactory<DetailCubit>(
    () => DetailCubit(
      getComicDetail: getIt<GetComicDetail>(),
      logger: getIt<Logger>(),
    ),
  );

  // ============================================
  // 7. SERVICES (App-level)
  // ============================================

  getIt.registerLazySingleton<LicenseService>(() => LicenseService(
        dio: getIt<Dio>(),
        logger: getIt<Logger>(),
        remoteConfigService: getIt<RemoteConfigService>(),
        prefs: getIt<SharedPreferences>(),
        secureStorage: getIt<FlutterSecureStorage>(),
      ));

  getIt.registerLazySingleton<AdService>(() => AdService(
        licenseService: getIt<LicenseService>(),
        logger: getIt<Logger>(),
      ));

  getIt.registerLazySingleton<DownloadService>(() => DownloadService(
        dio: getIt<Dio>(),
        logger: getIt<Logger>(),
        licenseService: getIt<LicenseService>(),
      ));
}

/// Initialize async dependencies
/// Call after configureDependencies(), before runApp()
Future<void> initializeServices() async {
  // Initialize DNS Settings
  await getIt<DnsSettingsService>().initialize();

  // Initialize License Service
  await getIt<LicenseService>().initialize();

  // Initialize other services that need async init
  await getIt<RemoteConfigService>().initialize();
}
```

---

## 🔧 Registration Types

### 1. Lazy Singleton (Most Common)

Created once, on first use:

```dart
getIt.registerLazySingleton<Logger>(() => Logger());

// Logger not created yet
final logger = getIt<Logger>(); // ← Created here (first time)
final logger2 = getIt<Logger>(); // ← Returns same instance
```

**Use for:** Services, repositories, data sources, use cases

---

### 2. Singleton (Eager)

Created immediately at registration:

```dart
getIt.registerSingleton<Dio>(Dio());

// Dio created immediately
```

**Use for:** 
- HTTP clients that need early initialization
- Services that configure other services
- When you need to avoid lazy resolution issues

---

### 3. Factory (New Instance Each Time)

Creates new instance every call:

```dart
getIt.registerFactory<ComicCubit>(() => ComicCubit());

final cubit1 = getIt<ComicCubit>(); // New instance
final cubit2 = getIt<ComicCubit>(); // Another new instance
```

**Use for:** 
- Cubits/BLoCs (screen-scoped state)
- Short-lived objects
- When you don't want shared state

---

### 4. Async Factory/Singleton

For async initialization:

```dart
// Async singleton
await getIt.registerSingletonAsync<Database>(() => Database.open());

// Wait for completion
await getIt.allReady();

// Async factory
getIt.registerFactoryAsync<ComplexService>(() async {
  await Future.delayed(Duration(seconds: 1));
  return ComplexService();
});
```

---

## 🎯 Best Practices

### DO ✅

```dart
// ✅ Use clear variable names
getIt.registerLazySingleton<ComicRepository>(
  () => ComicRepositoryImpl(
    remoteDataSource: getIt<ComicRemoteDataSource>(),
    localDataSource: getIt<ComicLocalDataSource>(),
  ),
);

// ✅ Group related registrations with comments
// ============================================
// DATA SOURCES
// ============================================

// ✅ Handle circular dependencies with registration order
getIt.registerLazySingleton<A>(() => A(getIt<B>()));
getIt.registerLazySingleton<B>(() => B(getIt<C>()));
getIt.registerLazySingleton<C>(() => C());

// ✅ Use async initialization for services
Future<void> initializeServices() async {
  await getIt<LicenseService>().initialize();
}
```

### DON'T ❌

```dart
// ❌ Don't use service locator in domain layer
class GetComics {
  void call() {
    final repo = getIt<ComicRepository>(); // WRONG!
  }
}

// ✅ Inject via constructor
class GetComics {
  final ComicRepository repository;
  GetComics(this.repository);
}

// ❌ Don't register without clear dependency order
getIt.registerSingleton<Dio>(Dio());
getIt.registerSingleton<RemoteConfigService>(RemoteConfigService(dio: getIt<Dio>()));
// What if RemoteConfigService needs to be used during Dio init?

// ❌ Don't use getIt directly in widgets
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = getIt<ComicCubit>(); // WRONG!
    return BlocProvider.value(value: cubit, child: ...);
  }
}

// ✅ Use BlocProvider with getIt in create
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ComicCubit>(),
      child: ...,
    );
  }
}
```

---

## 🧪 Testing with DI

### Mock Registration for Tests

```dart
// test/presentation/cubits/comic_cubit_test.dart
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockComicRepository extends Mock implements ComicRepository {}
class MockGetComics extends Mock implements GetComics {}

void main() {
  late GetIt testGetIt;

  setUp(() {
    testGetIt = GetIt.instance;
    testGetIt.reset(); // Clear previous registrations
    
    // Register mocks
    testGetIt.registerLazySingleton<ComicRepository>(() => MockComicRepository());
    testGetIt.registerFactory<ComicCubit>(() => ComicCubit(
      getComics: testGetIt<GetComics>(),
    ));
  });

  tearDown(() {
    testGetIt.reset();
  });

  test('should load comics', () {
    final cubit = testGetIt<ComicCubit>();
    // Test...
  });
}
```

---

## 🔍 Debugging DI Issues

### Common Problems

#### 1. "No instance found" Error

```dart
// ❌ Error: GetIt: Object/factory with type Logger is not registered
getIt.registerLazySingleton<Service>(() => Service(getIt<Logger>()));

// ✅ Fix: Register Logger FIRST
getIt.registerLazySingleton<Logger>(() => Logger());
getIt.registerLazySingleton<Service>(() => Service(getIt<Logger>()));
```

#### 2. Circular Dependency

```dart
// ❌ Error: Stack overflow (A needs B, B needs A)
getIt.registerLazySingleton<A>(() => A(getIt<B>()));
getIt.registerLazySingleton<B>(() => B(getIt<A>()));

// ✅ Fix: Break the cycle
// Option 1: Use late initialization
getIt.registerLazySingleton<A>(() => A());
getIt.registerLazySingleton<B>(() => B(a: getIt<A>()));

// Option 2: Use setter injection
class B {
  A? a;
  void setA(A a) => this.a = a;
}
```

#### 3. Async Initialization Race

```dart
// ❌ Problem: Dio uses DnsResolver, but DnsResolver not ready
getIt.registerSingleton<Dio>(HttpClientManager.initializeHttpClient(
  dnsResolver: getIt<DnsResolver>(),
));

// ✅ Fix: Use eager singleton for Dio, ensure DnsResolver registered first
getIt.registerLazySingleton<DnsResolver>(() => DnsResolver());
getIt.registerSingleton<Dio>(HttpClientManager.initializeHttpClient(
  dnsResolver: getIt<DnsResolver>(),
));
```

---

## 📋 Checklist for New Dependencies

When adding a new dependency:

- [ ] Determine registration type (LazySingleton, Singleton, Factory)
- [ ] Identify all dependencies (what does this need?)
- [ ] Find correct position in registration order
- [ ] Add to `configureDependencies()`
- [ ] Add async init to `initializeServices()` if needed
- [ ] Update tests with mock registration
- [ ] Document in this file if it's a special case

---

## 📚 Advanced Patterns

### Module Pattern (for large apps)

Split DI into modules for better organization:

```dart
// lib/core/di/modules/network_module.dart
abstract class NetworkModule {
  static void register() {
    getIt.registerLazySingleton<DnsSettingsService>(...);
    getIt.registerLazySingleton<DnsResolver>(...);
    getIt.registerSingleton<Dio>(...);
  }
}

// lib/core/di/modules/data_module.dart
abstract class DataModule {
  static void register() {
    getIt.registerLazySingleton<ComicRemoteDataSource>(...);
    getIt.registerLazySingleton<ComicLocalDataSource>(...);
    getIt.registerLazySingleton<ComicRepository>(...);
  }
}

// lib/core/di/service_locator.dart
Future<void> configureDependencies() async {
  NetworkModule.register();
  DataModule.register();
  DomainModule.register();
  PresentationModule.register();
}
```

### Conditional Registration

Register different implementations based on flavor/environment:

```dart
if (kReleaseMode) {
  getIt.registerLazySingleton<ApiService>(() => ProductionApiService());
} else {
  getIt.registerLazySingleton<ApiService>(() => MockApiService());
}
```

---

## 📚 References

- [GetIt Package](https://pub.dev/packages/get_it)
- [GetIt GitHub](https://github.com/fluttercommunity/get_it)
- [Dependency Injection in Flutter](https://docs.flutter.dev/development/data-and-backend/state-mgmt/advanced#dependency-injection)
- [Service Locator Pattern](https://en.wikipedia.org/wiki/Service_locator_pattern)
