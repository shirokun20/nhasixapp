import '../base_usecase.dart';
import '../../entities/entities.dart';
import '../../repositories/repositories.dart';

/// Use case for getting all downloads with optional filtering
class GetAllDownloadsUseCase
    extends UseCase<List<DownloadStatus>, GetAllDownloadsParams> {
  GetAllDownloadsUseCase(this._userDataRepository);

  final UserDataRepository _userDataRepository;

  @override
  Future<List<DownloadStatus>> call(GetAllDownloadsParams params) async {
    try {
      // Validate parameters
      if (params.page < 1) {
        throw const ValidationException('Page number must be greater than 0');
      }

      if (params.limit < 1 || params.limit > 100) {
        throw const ValidationException('Limit must be between 1 and 100');
      }

      // Get downloads from repository
      final downloads = await _userDataRepository.getAllDownloads(
        state: params.state,
        page: params.page,
        limit: params.limit,
      );

      return downloads;
    } on UseCaseException {
      rethrow;
    } catch (e) {
      throw CacheException('Failed to get downloads: ${e.toString()}');
    }
  }
}

/// Parameters for GetAllDownloadsUseCase
class GetAllDownloadsParams extends UseCaseParams {
  const GetAllDownloadsParams({
    this.state,
    this.page = 1,
    this.limit = 20,
  });

  final DownloadState? state;
  final int page;
  final int limit;

  @override
  List<Object?> get props => [state, page, limit];

  GetAllDownloadsParams copyWith({
    DownloadState? state,
    int? page,
    int? limit,
  }) {
    return GetAllDownloadsParams(
      state: state ?? this.state,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  /// Create params for all downloads
  factory GetAllDownloadsParams.all({int page = 1, int limit = 20}) {
    return GetAllDownloadsParams(page: page, limit: limit);
  }

  /// Create params for active downloads only
  factory GetAllDownloadsParams.active({int page = 1, int limit = 20}) {
    return GetAllDownloadsParams(
      state: DownloadState.downloading,
      page: page,
      limit: limit,
    );
  }

  /// Create params for queued downloads only
  factory GetAllDownloadsParams.queued({int page = 1, int limit = 20}) {
    return GetAllDownloadsParams(
      state: DownloadState.queued,
      page: page,
      limit: limit,
    );
  }

  /// Create params for completed downloads only
  factory GetAllDownloadsParams.completed({int page = 1, int limit = 20}) {
    return GetAllDownloadsParams(
      state: DownloadState.completed,
      page: page,
      limit: limit,
    );
  }

  /// Create params for failed downloads only
  factory GetAllDownloadsParams.failed({int page = 1, int limit = 20}) {
    return GetAllDownloadsParams(
      state: DownloadState.failed,
      page: page,
      limit: limit,
    );
  }

  /// Create params for paused downloads only
  factory GetAllDownloadsParams.paused({int page = 1, int limit = 20}) {
    return GetAllDownloadsParams(
      state: DownloadState.paused,
      page: page,
      limit: limit,
    );
  }

  /// Create params for cancelled downloads only
  factory GetAllDownloadsParams.cancelled({int page = 1, int limit = 20}) {
    return GetAllDownloadsParams(
      state: DownloadState.cancelled,
      page: page,
      limit: limit,
    );
  }
}
