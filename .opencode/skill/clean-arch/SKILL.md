---
name: clean-arch
description: Panduan implementasi Clean Architecture untuk NhasixApp dengan layer domain, data, dan presentation
license: MIT
compatibility: opencode
metadata:
  audience: developers
  pattern: clean-architecture
---

## Clean Architecture Guide untuk NhasixApp

### Struktur Layer

```
lib/
├── core/                    # Shared utilities
│   ├── di/                  # Dependency Injection (GetIt)
│   ├── error/               # Failure classes
│   ├── network/             # API client, interceptors
│   ├── utils/               # Helpers, extensions
│   └── widgets/             # Reusable widgets
│
├── features/
│   └── [feature_name]/
│       ├── domain/          # Business logic (innermost)
│       │   ├── entities/    # Pure Dart classes
│       │   ├── repositories/ # Abstract repository interfaces
│       │   └── usecases/    # Business use cases
│       │
│       ├── data/            # Data layer (middle)
│       │   ├── models/      # DTOs, extends entities
│       │   ├── datasources/ # Remote/Local data sources
│       │   └── repositories/ # Repository implementations
│       │
│       └── presentation/    # UI layer (outermost)
│           ├── bloc/        # BLoC/Cubit state management
│           ├── pages/       # Screen widgets
│           └── widgets/     # Feature-specific widgets
```

### Dependency Rule

**PENTING**: Dependencies hanya boleh mengarah ke dalam:
- `presentation` → `domain` ✅
- `data` → `domain` ✅
- `domain` → `data` ❌ (DILARANG!)
- `domain` → `presentation` ❌ (DILARANG!)

### Layer Details

#### 1. Domain Layer (Core Business Logic)

**Entities** - Pure Dart objects tanpa dependencies eksternal:
```dart
class User {
  final String id;
  final String name;
  final String email;
  
  const User({
    required this.id,
    required this.name,
    required this.email,
  });
}
```

**Repository Interface** - Abstract contracts:
```dart
abstract class UserRepository {
  Future<Either<Failure, User>> getUser(String id);
  Future<Either<Failure, List<User>>> getUsers();
}
```

**Use Cases** - Single responsibility business operations:
```dart
class GetUserUseCase {
  final UserRepository repository;
  
  GetUserUseCase(this.repository);
  
  Future<Either<Failure, User>> call(String userId) {
    return repository.getUser(userId);
  }
}
```

#### 2. Data Layer (Data Access)

**Models** - Extends entities dengan serialization:
```dart
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
  });
  
  factory UserModel.fromEntity(User entity) => UserModel(
    id: entity.id,
    name: entity.name,
    email: entity.email,
  );
  
  User toEntity() => User(id: id, name: name, email: email);
  
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] as String,
    name: map['name'] as String,
    email: map['email'] as String,
  );
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
  };
}
```

**Data Sources**:
```dart
abstract class UserRemoteDataSource {
  Future<UserModel> getUser(String id);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient client;
  
  UserRemoteDataSourceImpl(this.client);
  
  @override
  Future<UserModel> getUser(String id) async {
    final response = await client.get('/users/$id');
    return UserModel.fromMap(response.data);
  }
}
```

**Repository Implementation**:
```dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  
  UserRepositoryImpl(this.remoteDataSource);
  
  @override
  Future<Either<Failure, User>> getUser(String id) async {
    try {
      final result = await remoteDataSource.getUser(id);
      return Right(result.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

#### 3. Presentation Layer (UI)

Lihat skill `bloc-cubit` untuk detail state management.

### Dependency Injection dengan GetIt

Lokasi: `core/di/injection_container.dart`

```dart
final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs / Cubits
  sl.registerFactory(() => UserCubit(sl()));
  
  // Use Cases
  sl.registerLazySingleton(() => GetUserUseCase(sl()));
  
  // Repositories
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl()),
  );
  
  // Data Sources
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(sl()),
  );
  
  // External
  sl.registerLazySingleton(() => ApiClient());
}
```

### Checklist Implementasi Feature Baru

1. [ ] Buat entity di `domain/entities/`
2. [ ] Buat repository interface di `domain/repositories/`
3. [ ] Buat use case di `domain/usecases/`
4. [ ] Buat model (extends entity) di `data/models/`
5. [ ] Buat data source di `data/datasources/`
6. [ ] Implementasi repository di `data/repositories/`
7. [ ] Buat Cubit/BLoC di `presentation/bloc/`
8. [ ] Buat UI di `presentation/pages/`
9. [ ] Register semua di DI container
