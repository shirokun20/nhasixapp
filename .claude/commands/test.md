# Generate Tests

Generate comprehensive unit tests for a Dart class.

## Usage
`/test $ARGUMENTS`

Provide the file path to generate tests for.

## Process

1. **Analyze**: Read `$ARGUMENTS` to understand dependencies and logic
2. **Mock**: Identify dependencies to mock using `mocktail`
3. **Plan**: Determine test cases — happy path, error cases, edge cases
4. **Generate**: Write the test file

## Test Placement
Mirror the source structure under `test/`:
- `lib/domain/usecases/get_user.dart` -> `test/domain/usecases/get_user_test.dart`
- `lib/presentation/cubit/user_cubit.dart` -> `test/presentation/cubit/user_cubit_test.dart`

## For BLoC/Cubit — use `bloc_test`

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetUserUseCase extends Mock implements GetUserUseCase {}

void main() {
  late UserCubit cubit;
  late MockGetUserUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetUserUseCase();
    cubit = UserCubit(mockUseCase);
  });

  tearDown(() => cubit.close());

  blocTest<UserCubit, UserState>(
    'emits [loading, loaded] when loadUser succeeds',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => DataSuccess(testUser));
      return cubit;
    },
    act: (cubit) => cubit.loadUser('123'),
    expect: () => [
      const UserState.loading(),
      UserState.loaded(testUser),
    ],
  );
}
```

## For Repository/UseCase — use standard `test`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRemoteDataSource extends Mock implements UserRemoteDataSource {}

void main() {
  late UserRepositoryImpl repository;
  late MockUserRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockUserRemoteDataSource();
    repository = UserRepositoryImpl(mockDataSource);
  });

  test('should return DataSuccess when remote call succeeds', () async {
    when(() => mockDataSource.getUser(any())).thenAnswer((_) async => testUserModel);
    final result = await repository.getUser('123');
    expect(result, isA<DataSuccess>());
  });
}
```

## Output
- Generate the full test file content
- Ask user for confirmation before writing to disk
