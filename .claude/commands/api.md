# API Integration

Step-by-step guide for integrating new API endpoints into NhasixApp's Clean Architecture.

Uses **manual GetIt DI** (no injectable codegen) and **DataState** pattern from `kuron_core`.

## File Checklist (in order)

1. **Entity**: `lib/domain/entities/[feature]/[name].dart`
2. **Model**: `lib/data/models/[feature]/[name]_model.dart`
3. **DataSource**: `lib/data/datasources/remote/[feature]_remote_data_source.dart`
4. **Repository Interface**: `lib/domain/repositories/[feature]_repository.dart`
5. **Repository Impl**: `lib/data/repositories/[feature]_repository_impl.dart`
6. **UseCase**: `lib/domain/usecases/[feature]/[action]_usecase.dart`
7. **DI Registration**: `lib/core/di/service_locator.dart`

## Step 1: Entity (Equatable)
```dart
class Comment extends Equatable {
  final String id;
  final String text;
  final String author;
  const Comment({required this.id, required this.text, required this.author});
  @override
  List<Object?> get props => [id, text, author];
}
```

## Step 2: Model (extends Entity, fromJson)
```dart
class CommentModel extends Comment {
  const CommentModel({required super.id, required super.text, required super.author});
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id']?.toString() ?? '',
      text: json['body'] ?? '',
      author: json['user']?['username'] ?? 'Anonymous',
    );
  }
}
```

## Step 3: Remote DataSource (Dio)
```dart
abstract class CommentRemoteDataSource {
  Future<List<CommentModel>> getComments(String contentId);
}

class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  final Dio _dio;
  CommentRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CommentModel>> getComments(String contentId) async {
    final response = await _dio.get('/api/gallery/$contentId/comments');
    if (response.statusCode == 200) {
      return (response.data as List).map((e) => CommentModel.fromJson(e)).toList();
    }
    throw DioException(requestOptions: response.requestOptions, response: response, type: DioExceptionType.badResponse);
  }
}
```

## Step 4: Repository Interface (DataState)
```dart
abstract class CommentRepository {
  Future<DataState<List<Comment>>> getComments(String contentId);
}
```

## Step 5: Repository Implementation (try-catch -> DataSuccess/DataFailed)
```dart
class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource _remoteDataSource;
  CommentRepositoryImpl(this._remoteDataSource);

  @override
  Future<DataState<List<Comment>>> getComments(String contentId) async {
    try {
      final result = await _remoteDataSource.getComments(contentId);
      return DataSuccess(result);
    } on DioException catch (e) {
      return DataFailed(e);
    }
  }
}
```

## Step 6: UseCase (single responsibility)
```dart
class GetCommentsUseCase implements UseCase<DataState<List<Comment>>, String> {
  final CommentRepository _repository;
  GetCommentsUseCase(this._repository);

  @override
  Future<DataState<List<Comment>>> call({String? params}) {
    if (params == null) throw ArgumentError('Content ID required');
    return _repository.getComments(params);
  }
}
```

## Step 7: DI Registration (CRITICAL)

Register in `lib/core/di/service_locator.dart`. **ALWAYS add imports at the top.**

```dart
// _setupDataSources()
getIt.registerLazySingleton<CommentRemoteDataSource>(
    () => CommentRemoteDataSourceImpl(getIt<Dio>()));

// _setupRepositories()
getIt.registerLazySingleton<CommentRepository>(
    () => CommentRepositoryImpl(getIt<CommentRemoteDataSource>()));

// _setupUseCases()
getIt.registerLazySingleton<GetCommentsUseCase>(
    () => GetCommentsUseCase(getIt<CommentRepository>()));
```

## Common Mistakes
1. **Lupa register DI** — "Object/Factory not found" error at runtime
2. **Wrong imports** — Use `package:nhasixapp/...` not deep relative paths across layers
3. **Not using DataState** — Repository MUST return `DataState<T>`, never raw data
