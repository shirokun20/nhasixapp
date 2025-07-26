import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../value_objects/value_objects.dart';
import '../../repositories/repositories.dart';

/// Use case for downloading content for offline reading
class DownloadContentUseCase
    extends UseCase<DownloadStatus, DownloadContentParams> {
  DownloadContentUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<DownloadStatus> call(DownloadContentParams params) async {
    try {
      // Validate parameters
      if (params.content.id.isEmpty) {
        throw const ValidationException('Content ID cannot be empty');
      }

      if (params.content.imageUrls.isEmpty) {
        throw const ValidationException('Content has no images to download');
      }

      if (params.priority < 0 || params.priority > 10) {
        throw const ValidationException('Priority must be between 0 and 10');
      }

      // Check if already downloaded (optional)
      if (params.checkExisting) {
        final isDownloaded = await _userDataRepository.isDownloaded(
          ContentId.fromString(params.content.id),
        );

        if (isDownloaded) {
          if (params.throwIfExists) {
            throw const ValidationException('Content is already downloaded');
          } else {
            // Return existing download status
            final existingStatus = await _userDataRepository.getDownloadStatus(
              ContentId.fromString(params.content.id),
            );
            return existingStatus ??
                DownloadStatus.completed(
                  params.content.id,
                  params.content.pageCount,
                  '', // Path will be filled by repository
                  0, // Size will be filled by repository
                );
          }
        }
      }

      // Queue download
      final downloadStatus = await _userDataRepository.queueDownload(
        content: params.content,
        priority: params.priority,
      );

      return downloadStatus;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to queue download: ${e.toString()}');
    }
  }
}

/// Parameters for DownloadContentUseCase
class DownloadContentParams extends UseCaseParams {
  const DownloadContentParams({
    required this.content,
    this.priority = 0,
    this.checkExisting = true,
    this.throwIfExists = false,
  });

  final Content content;
  final int priority;
  final bool checkExisting;
  final bool throwIfExists;

  @override
  List<Object> get props => [
        content,
        priority,
        checkExisting,
        throwIfExists,
      ];

  DownloadContentParams copyWith({
    Content? content,
    int? priority,
    bool? checkExisting,
    bool? throwIfExists,
  }) {
    return DownloadContentParams(
      content: content ?? this.content,
      priority: priority ?? this.priority,
      checkExisting: checkExisting ?? this.checkExisting,
      throwIfExists: throwIfExists ?? this.throwIfExists,
    );
  }

  /// Create params with normal priority
  factory DownloadContentParams.normal(Content content) {
    return DownloadContentParams(content: content, priority: 0);
  }

  /// Create params with high priority
  factory DownloadContentParams.highPriority(Content content) {
    return DownloadContentParams(content: content, priority: 5);
  }

  /// Create params with maximum priority
  factory DownloadContentParams.urgent(Content content) {
    return DownloadContentParams(content: content, priority: 10);
  }

  /// Create params with existing check disabled
  factory DownloadContentParams.force(Content content, {int priority = 0}) {
    return DownloadContentParams(
      content: content,
      priority: priority,
      checkExisting: false,
    );
  }

  /// Create params for batch download
  factory DownloadContentParams.batch(Content content, int batchPriority) {
    return DownloadContentParams(
      content: content,
      priority: batchPriority,
      checkExisting: true,
      throwIfExists: false, // Don't throw for batch operations
    );
  }
}
