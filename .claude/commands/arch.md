# Clean Architecture Guide

Implementation patterns for Kuron's Clean Architecture.

## Layer Structure

```
lib/
├── domain/                    # Pure Dart — NO Flutter, NO JSON
│   ├── entities/              # Business objects (Equatable)
│   ├── repositories/          # Abstract interfaces
│   └── usecases/              # Single-responsibility business logic
├── data/                      # Framework-dependent implementations
│   ├── models/                # DTOs extending entities (.fromEntity, .toEntity, .fromMap)
│   ├── datasources/           # Remote (Dio) / Local (SharedPreferences, DB)
│   └── repositories/          # Implements domain interfaces, returns DataState
└── presentation/              # Flutter UI
    ├── bloc/                  # State management (extends BaseCubit)
    ├── pages/                 # Screens
    └── widgets/               # Reusable components
```

## Dependency Rule (STRICT)

```
Presentation -> Domain    OK
Data -> Domain            OK
Domain -> Data            FORBIDDEN
Domain -> Presentation    FORBIDDEN
Presentation -> Data      FORBIDDEN (go through Domain)
```

## Templates

### Entity
```dart
class User extends Equatable {
  final String id;
  final String name;
  const User({required this.id, required this.name});
  @override
  List<Object?> get props => [id, name];
}
```

### Repository Interface
```dart
abstract class UserRepository {
  Future<DataState<User>> getUser(String id);
}
```

### UseCase
```dart
class GetUserUseCase implements UseCase<DataState<User>, String> {
  final UserRepository _repository;
  GetUserUseCase(this._repository);
  @override
  Future<DataState<User>> call({String? params}) => _repository.getUser(params!);
}
```

### Model (extends Entity)
```dart
class UserModel extends User {
  const UserModel({required super.id, required super.name});

  factory UserModel.fromMap(Map<String, dynamic> map) =>
    UserModel(id: map['id'] as String, name: map['name'] as String);

  factory UserModel.fromEntity(User entity) =>
    UserModel(id: entity.id, name: entity.name);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
  User toEntity() => this;
}
```

### Repository Implementation
```dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remote;
  UserRepositoryImpl(this._remote);

  @override
  Future<DataState<User>> getUser(String id) async {
    try {
      final model = await _remote.getUser(id);
      return DataSuccess(model);
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}
```

## Common Mistakes
- Importing data layer in domain layer
- Using Flutter/framework types in entities
- Direct instantiation instead of DI
- Business logic in UI layer
- Repository returning raw data instead of DataState
