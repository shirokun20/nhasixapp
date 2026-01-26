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
      if (params.offset < 0) {
        throw const ValidationException('Offset must be >= 0');
      }

      if (params.limit < 1 || params.limit > 100) {
        throw const ValidationException('Limit must be between 1 and 100');
      }

      // Get downloads from repository
      final downloads = await _userDataRepository.getAllDownloads(
        state: params.state,
        limit: params.limit,
        offset: params.offset,
        orderBy: params.orderBy,
        descending: params.descending,
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
    this.limit = 20,
    this.offset = 0,
    this.orderBy = 'created_at',
    this.descending = true,
  });

  final DownloadState? state;
  final int limit;
  final int offset;
  final String orderBy;
  final bool descending;

  @override
  List<Object?> get props => [state, limit, offset, orderBy, descending];

  GetAllDownloadsParams copyWith({
    DownloadState? state,
    int? limit,
    int? offset,
    String? orderBy,
    bool? descending,
  }) {
    return GetAllDownloadsParams(
      state: state ?? this.state,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      orderBy: orderBy ?? this.orderBy,
      descending: descending ?? this.descending,
    );
  }

  /// Create params for all downloads
  factory GetAllDownloadsParams.all({int limit = 20, int offset = 0}) {
    return GetAllDownloadsParams(limit: limit, offset: offset);
  }

  /// Create params for active downloads only
  factory GetAllDownloadsParams.active({int limit = 20, int offset = 0}) {
    return GetAllDownloadsParams(
      state: DownloadState.downloading,
      limit: limit,
      offset: offset,
    );
  }

  /// Create params for queued downloads only
  factory GetAllDownloadsParams.queued({int limit = 20, int offset = 0}) {
    return GetAllDownloadsParams(
      state: DownloadState.queued,
      limit: limit,
      offset: offset,
    );
  }

  /// Create params for completed downloads only
  factory GetAllDownloadsParams.completed({int limit = 20, int offset = 0}) {
    return GetAllDownloadsParams(
      state: DownloadState.completed,
      limit: limit,
      offset: offset,
    );
  }

  /// Create params for failed downloads only
  factory GetAllDownloadsParams.failed({int limit = 20, int offset = 0}) {
    return GetAllDownloadsParams(
      state: DownloadState.failed,
      limit: limit,
      offset: offset,
    );
  }

  /// Create params for paused downloads only
  factory GetAllDownloadsParams.paused({int limit = 20, int offset = 0}) {
    return GetAllDownloadsParams(
      state: DownloadState.paused,
      limit: limit,
      offset: offset,
    );
  }

  /// Create params for cancelled downloads only
  factory GetAllDownloadsParams.cancelled({int limit = 20, int offset = 0}) {
    return GetAllDownloadsParams(
      state: DownloadState.cancelled,
      limit: limit,
      offset: offset,
    );
  }
}
