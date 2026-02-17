---
name: clean-arch
description: Implement Clean Architecture patterns for Flutter - domain/data/presentation layers
license: MIT
compatibility: opencode
metadata:
  category: architecture
  framework: flutter
  project: nhasixapp
---

# Clean Architecture Skill for NhasixApp

This skill guides you through implementing Clean Architecture patterns in Flutter.

## Layer Structure

```
lib/
├── domain/
│   ├── entities/          # Pure business objects
│   ├── repositories/      # Abstract interfaces
│   └── usecases/          # Business logic
├── data/
│   ├── models/            # DTOs extending entities
│   ├── datasources/       # Remote/Local sources
│   └── repositories/      # Implementation
└── presentation/
    ├── bloc/              # State management
    ├── pages/             # Screens
    └── widgets/           # Reusable UI
```

## Creating an Entity

```dart
// domain/entities/user.dart
class User extends Equatable {
  final String id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  @override
  List<Object?> get props => [id, name, email];
}
```

## Creating a Repository Interface

```dart
// domain/repositories/user_repository.dart
abstract class UserRepository {
  Future<Either<Failure, User>> getUser(String id);
  Future<Either<Failure, User>> updateUser(User user);
}
```

## Creating a Use Case

```dart
// domain/usecases/get_user.dart
class GetUserUseCase implements UseCase<User, GetUserParams> {
  final UserRepository repository;

  GetUserUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(GetUserParams params) {
    return repository.getUser(params.id);
  }
}

class GetUserParams {
  final String id;
  GetUserParams(this.id);
}
```

## Creating a Model

```dart
// data/models/user_model.dart
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
    );
  }

  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  User toEntity() => this;
}
```

## Creating Repository Implementation

```dart
// data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> getUser(String id) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure());
    }
    try {
      final userModel = await remoteDataSource.getUser(id);
      return Right(userModel.toEntity());
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
```

## Key Principles

1. **Dependency Rule**: Dependencies point inward (Domain has no dependencies)
2. **Entity**: Enterprise business rules
3. **Use Cases**: Application business rules
4. **Interface Adapters**: Convert data for use cases and entities
5. **Frameworks**: External tools (Flutter, Dio, etc.)

## Common Mistakes to Avoid

- ❌ Importing data layer in domain layer
- ❌ Using framework-specific types in entities
- ❌ Direct instantiation instead of DI
- ❌ Business logic in UI layer

## When to Use

- Implementing new features
- Refactoring legacy code
- Code reviews
- Architecture planning
