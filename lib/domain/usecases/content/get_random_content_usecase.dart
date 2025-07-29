import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/repositories.dart';

/// Use case for getting random content
class GetRandomContentUseCase extends UseCase<List<Content>, int> {
  GetRandomContentUseCase(this._contentRepository);

  final ContentRepository _contentRepository;

  static const int maxCount = 50;

  @override
  Future<List<Content>> call(int count) async {
    try {
      // Validate parameters
      if (count < 1) {
        throw const ValidationException('Count must be greater than 0');
      }

      if (count > maxCount) {
        throw ValidationException('Count cannot exceed $maxCount');
      }

      // Get random content from repository
      final content = await _contentRepository.getRandomContent(
        count: count,
      );

      return content;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw NetworkException('Failed to get random content: ${e.toString()}');
    }
  }
}

/// Parameters for GetRandomContentUseCase
class GetRandomContentParams extends UseCaseParams {
  const GetRandomContentParams({
    this.count = 1,
    this.maxCount = 20,
  });

  final int count;
  final int maxCount;

  @override
  List<Object> get props => [count, maxCount];

  GetRandomContentParams copyWith({
    int? count,
    int? maxCount,
  }) {
    return GetRandomContentParams(
      count: count ?? this.count,
      maxCount: maxCount ?? this.maxCount,
    );
  }

  /// Create params for single random content
  factory GetRandomContentParams.single() {
    return const GetRandomContentParams(count: 1);
  }

  /// Create params for multiple random content
  factory GetRandomContentParams.multiple(int count) {
    return GetRandomContentParams(count: count);
  }

  /// Create params for random content grid
  factory GetRandomContentParams.grid({int columns = 2, int rows = 3}) {
    final count = columns * rows;
    return GetRandomContentParams(count: count);
  }
}
