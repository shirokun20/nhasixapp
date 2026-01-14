---
name: api-integration
description: Panduan integrasi endpoint API baru ke dalam Clean Architecture NhasixApp (Data -> Domain)
---

# API Integration Skill (NhasixApp Specific)

Skill ini dirancang khusus untuk struktur Clean Architecture NhasixApp. Project ini menggunakan **Manual Dependency Injection (GetIt)** tanpa code generation (injectable), dan pola `DataState` untuk handling hasil repository.

## 📋 Checklist File

Urutan pengerjaan yang disarankan: **Domain (Entity)** -> **Data (Model)** -> **DataSource** -> **Domain (Repo)** -> **Data (Repo Impl)** -> **UseCase** -> **DI Registration**.

1.  **Entity**: `lib/domain/entities/[feature]/[name].dart`
2.  **Model**: `lib/data/models/[feature]/[name]_model.dart`
3.  **DataSource**: `lib/data/datasources/remote/[feature]_remote_data_source.dart`
4.  **Repository (Interface)**: `lib/domain/repositories/[feature]_repository.dart`
5.  **Repository (Impl)**: `lib/data/repositories/[feature]_repository_impl.dart`
6.  **UseCase**: `lib/domain/usecases/[feature]/[action]_usecase.dart`
7.  **DI**: `lib/core/di/service_locator.dart`

---

## 🛠️ Step-by-Step Implementation

### 1. Define Entity
Gunakan `Equatable` untuk value comparison.
```dart
// lib/domain/entities/comment/comment.dart
import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String text;
  final String author;

  const Comment({
    required this.id,
    required this.text,
    required this.author,
  });

  @override
  List<Object?> get props => [id, text, author];
}
```

### 2. Define Model (DTO)
Extend Entity, tambah `fromJson`/`toJson`. Pastikan null safety handled.
```dart
// lib/data/models/comment/comment_model.dart
import '../../../domain/entities/comment/comment.dart';

class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.text,
    required super.author,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id']?.toString() ?? '',
      text: json['body'] ?? '',
      author: json['user']?['username'] ?? 'Anonymous',
    );
  }
}
```

### 3. Create/Update Remote DataSource
Project ini memisahkan Logic Scraper dan API Client. Jika fetch dari API, gunakan `Dio`.
```dart
// lib/data/datasources/remote/comment_remote_data_source.dart
import 'package:dio/dio.dart';
import '../../models/comment/comment_model.dart';

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
      return (response.data as List)
          .map((e) => CommentModel.fromJson(e))
          .toList();
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
  }
}
```

### 4. Repository Interface
Gunakan `DataState` dari `kuron_core` atau local definition.
```dart
// lib/domain/repositories/comment_repository.dart
import 'package:kuron_core/kuron_core.dart'; // or local DataState import
import '../entities/comment/comment.dart';

abstract class CommentRepository {
  Future<DataState<List<Comment>>> getComments(String contentId);
}
```

### 5. Repository Implementation
Wrap call dengan try-catch dan return `DataSuccess` atau `DataFailed`.
```dart
// lib/data/repositories/comment_repository_impl.dart
import 'package:kuron_core/kuron_core.dart';
import 'package:dio/dio.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/entities/comment/comment.dart';
import '../datasources/remote/comment_remote_data_source.dart';

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
    } catch (e) {
      return DataFailed(DioException(
        requestOptions: RequestOptions(path: ''),
        error: e.toString(),
      ));
    }
  }
}
```

### 6. UseCase
Single responsibility class.
```dart
// lib/domain/usecases/comment/get_comments_usecase.dart
import 'package:kuron_core/kuron_core.dart';
import '../../repositories/comment_repository.dart';
import '../../entities/comment/comment.dart';

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

### 7. Dependency Injection (CRITICAL)
Register manual di `lib/core/di/service_locator.dart`.
**JANGAN LUPA IMPORT FILE BARU DI BAGIAN ATAS `service_locator.dart`**

```dart
// Di dalam function _setupDataSources()
getIt.registerLazySingleton<CommentRemoteDataSource>(
    () => CommentRemoteDataSourceImpl(getIt<Dio>()));

// Di dalam function _setupRepositories()
getIt.registerLazySingleton<CommentRepository>(
    () => CommentRepositoryImpl(getIt<CommentRemoteDataSource>()));

// Di dalam function _setupUseCases()
getIt.registerLazySingleton<GetCommentsUseCase>(
    () => GetCommentsUseCase(getIt<CommentRepository>()));
```

## ⚠️ Common Mistakes in NhasixApp
1.  **Lupa Register DI**: UseCase akan error "Object/Factory not found" saat dipanggil Bloc.
2.  **Salah Import**: Pastikan import dari `package:nhasixapp/...` bukan relative path yang terlalu jauh `../../..` jika lintas layer (misal repository impl ke domain entities).
3.  **DataState**: Project ini sangat bergantung pada `DataState` (Success/Failed) untuk flow control di Bloc. Jangan return raw data dari Repository.
