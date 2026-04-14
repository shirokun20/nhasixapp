import '../../../domain/value_objects/value_objects.dart';
import '../../../domain/usecases/content/content_usecases.dart';
import '../../../domain/usecases/content/get_content_detail_usecase.dart';
import '../../../domain/usecases/favorites/favorites_usecases.dart';
import '../../../domain/repositories/repositories.dart';
import '../../../core/models/image_metadata.dart';
import '../../../core/utils/offline_content_manager.dart';
import '../../../services/image_metadata_service.dart';
import '../base/base_cubit.dart';
import 'package:kuron_core/kuron_core.dart';
import '../../../../core/utils/error_message_utils.dart';
import '../../../domain/entities/history.dart';

part 'detail_state.dart';

/// Cubit for managing content detail view and favorite toggle
/// Simple state management for detail screen operations
class DetailCubit extends BaseCubit<DetailState> {
  DetailCubit({
    required GetContentDetailUseCase getContentDetailUseCase,
    required AddToFavoritesUseCase addToFavoritesUseCase,
    required RemoveFromFavoritesUseCase removeFromFavoritesUseCase,
    required UserDataRepository userDataRepository,
    required ImageMetadataService imageMetadataService,
    required ContentRepository contentRepository,
    required ContentSourceRegistry contentSourceRegistry,
    required OfflineContentManager offlineContentManager,
    required super.logger,
  })  : _getContentDetailUseCase = getContentDetailUseCase,
        _addToFavoritesUseCase = addToFavoritesUseCase,
        _removeFromFavoritesUseCase = removeFromFavoritesUseCase,
        _userDataRepository = userDataRepository,
        _imageMetadataService = imageMetadataService,
        _contentRepository = contentRepository,
        _contentSourceRegistry = contentSourceRegistry,
        _offlineContentManager = offlineContentManager,
        super(
          initialState: const DetailInitial(),
        );

  final GetContentDetailUseCase _getContentDetailUseCase;
  final AddToFavoritesUseCase _addToFavoritesUseCase;
  final RemoveFromFavoritesUseCase _removeFromFavoritesUseCase;
  final UserDataRepository _userDataRepository;
  final ImageMetadataService _imageMetadataService;
  final ContentRepository _contentRepository;
  final ContentSourceRegistry _contentSourceRegistry;
  final OfflineContentManager _offlineContentManager;

  /// Load content detail by ID
  Future<void> loadContentDetail(String contentId, {String? sourceId}) async {
    try {
      logInfo('Loading content detail for ID: $contentId');
      emit(const DetailLoading());

      final params = GetContentDetailParams.fromString(
        contentId,
        sourceId: sourceId,
      );
      final content = await _getContentDetailUseCase(params);

      if (isClosed) return;

      // Check if content is favorited
      // For Crotpedia, we might need to check remote status if possible,
      // but usually we rely on local state or initial fetch status.
      // CrotpediaSource.getDetail should ideally return 'favorites' status if available.
      // Current implementation relies on UserDataRepository (Local DB) for 'isFavorited'.
      // If we want Crotpedia bookmarks to be source-of-truth, we may need to adjust.
      // BUT for now, let's keep consistency:
      // If Crotpedia, we might check local DB too? No, logic says Crotpedia bookmarks are REMOTE.
      // So checking _userDataRepository.isFavorite(contentId) might be wrong for Crotpedia if it's not synced.
      // Assuming 'isFavorited' in DetailLoaded is primarily for UI toggle state.

      bool isFavorited = false;
      if (content.sourceId == SourceType.crotpedia.id) {
        // Crotpedia content entity might have favorited status from source if parser supports it
        // But current parser just aggregates chapters.
        // We'll rely on what getDetail returns or check local if we decide to sync.
        // For now, let's assume getDetail sets content.favorites > 0 if bookmarked?
        // No, CrotpediaSource returns content.favorites = 0 (not available).
        // So we probably need to check local DB if we treat it as hybrid,
        // OR just assume false until user toggles (which is bad UX).
        // Ideally, CrotpediaSource should check bookmark status during getDetail if logged in.
        // Let's stick to existing code for now and refine if needed.
        isFavorited = await _checkIfFavorited(
          contentId,
          sourceId: content.sourceId,
        );
      } else {
        isFavorited = await _checkIfFavorited(
          contentId,
          sourceId: content.sourceId,
        );
      }

      // Generate image metadata for performance optimization
      final imageMetadata =
          await generateImageMetadata(contentId, content.imageUrls);

      if (isClosed) return;

      // Load chapter history
      final chapterHistoryList =
          await _userDataRepository.getAllChapterHistory(contentId);
      final chapterHistory = {
        for (var history in chapterHistoryList) history.chapterId!: history
      };

      if (isClosed) return;

      // Fetch related content and comments in parallel (non-blocking)
      List<Content>? relatedContent;
      List<Comment>? comments;

      try {
        // Get the content source to call getRelated and getComments
        final source = _contentSourceRegistry.getSource(content.sourceId);
        if (source != null) {
          final relatedFuture =
              source.getRelated(content.id).catchError((_) => <Content>[]);
          final commentsFuture =
              source.getComments(content.id).catchError((_) => <Comment>[]);

          final results = await Future.wait([
            relatedFuture,
            commentsFuture,
          ]);

          relatedContent = results[0] as List<Content>;
          comments = results[1] as List<Comment>;

          logInfo(
              'Fetched ${relatedContent.length} related, ${comments.length} comments for content: ${content.id}');
        }
      } catch (e, stackTrace) {
        handleError(e, stackTrace, 'fetch related/comments');
        logWarning(
            'Failed to fetch related/comments for content: ${content.id}');
        // Continue anyway - not critical
      }

      if (isClosed) return;

      emit(DetailLoaded(
        content: content,
        isFavorited: isFavorited,
        lastUpdated: DateTime.now(),
        imageMetadata: imageMetadata,
        chapterHistory: chapterHistory,
        relatedContent: relatedContent,
        comments: comments,
      ));

      logInfo('Successfully loaded content detail: ${content.title}');
    } on LoginRequiredException catch (e) {
      if (isClosed) return;

      emit(DetailError(
        message: e.message,
        errorType: 'login_required',
        canRetry: false,
        contentId: contentId,
        error: e,
      ));
    } catch (e, stackTrace) {
      if (isClosed) return;
      handleError(e, stackTrace, 'load content detail');

      final errorType = determineErrorType(e);
      final message = ErrorMessageUtils.getFriendlyErrorMessage(e);

      emit(DetailError(
        message: message,
        errorType: errorType,
        canRetry: isRetryableError(errorType),
        contentId: contentId,
        error: e,
      ));
    }
  }

  /// Load related content separately (independent API call)
  /// Should be called after loadContentDetail completes successfully
  Future<void> loadRelatedContent() async {
    final currentState = state;
    if (currentState is! DetailLoaded) {
      logWarning('Cannot load related content: content not loaded');
      return;
    }

    // Only load related content for Nhentai
    // Crotpedia's implementation is inefficient (calls getDetail again)
    // and can cause state issues
    if (currentState.content.sourceId != SourceType.nhentai.id) {
      logInfo(
          'Skipping related content for source: ${currentState.content.sourceId}');
      return;
    }

    try {
      logInfo('Loading related content for ID: ${currentState.content.id}');

      final contentId = ContentId(currentState.content.id);
      final relatedContents = await _contentRepository.getRelatedContent(
        contentId: contentId,
        limit: 10,
      );

      if (isClosed) return;

      if (relatedContents.isNotEmpty) {
        // Create updated content with related items
        final updatedContent = Content(
          sourceId: currentState.content.sourceId,
          id: currentState.content.id,
          title: currentState.content.title,
          coverUrl: currentState.content.coverUrl,
          tags: currentState.content.tags,
          artists: currentState.content.artists,
          characters: currentState.content.characters,
          parodies: currentState.content.parodies,
          groups: currentState.content.groups,
          language: currentState.content.language,
          pageCount: currentState.content.pageCount,
          imageUrls: currentState.content.imageUrls,
          uploadDate: currentState.content.uploadDate,
          favorites: currentState.content.favorites,
          englishTitle: currentState.content.englishTitle,
          japaneseTitle: currentState.content.japaneseTitle,
          relatedContent: relatedContents,
          // CRITICAL FIX: Preserve chapters field to prevent UI from switching
          // from chapter list to "Read Now" button
          chapters: currentState.content.chapters,
        );

        emit(currentState.copyWith(
          content: updatedContent,
          lastUpdated: DateTime.now(),
        ));

        logInfo(
            'Successfully loaded ${relatedContents.length} related content items');
      } else {
        logInfo('No related content found');
      }
    } catch (e, stackTrace) {
      // Don't fail the whole page, just log the error
      handleError(e, stackTrace, 'load related content');
      logWarning('Failed to load related content: ${e.toString()}');
    }
  }

  /// Toggle favorite status of current content
  Future<void> toggleFavorite() async {
    final currentState = state;
    if (currentState is! DetailLoaded) {
      logWarning('Cannot toggle favorite: content not loaded');
      return;
    }

    // DEFAULT HANDLING (Nhentai / Local)
    try {
      logInfo('Toggling favorite for content: ${currentState.content.id}');

      // Show optimistic update
      emit(currentState.copyWith(
        isFavorited: !currentState.isFavorited,
        isTogglingFavorite: true,
      ));

      // Perform actual toggle operation
      if (currentState.isFavorited) {
        await _removeFromFavorites(
          currentState.content.id,
          sourceId: currentState.content.sourceId,
        );
        logInfo('Removed from favorites: ${currentState.content.title}');
      } else {
        await _addToFavorites(currentState.content);
        logInfo('Added to favorites: ${currentState.content.title}');
      }

      if (isClosed) return;

      // Update state with final result
      emit(currentState.copyWith(
        isFavorited: !currentState.isFavorited,
        isTogglingFavorite: false,
        lastUpdated: DateTime.now(),
      ));
    } catch (e, stackTrace) {
      if (isClosed) return;
      handleError(e, stackTrace, 'toggle favorite');

      // Revert optimistic update on error
      emit(currentState.copyWith(
        isFavorited: currentState.isFavorited, // Revert to original state
        isTogglingFavorite: false,
      ));

      // Show error as snackbar or toast (handled by UI)
      logWarning('Failed to toggle favorite: ${e.toString()}');
    }
  }

  /// Refresh content detail
  Future<void> refreshContent() async {
    final currentState = state;
    if (currentState is DetailLoaded) {
      logInfo('Refreshing content detail');
      await loadContentDetail(currentState.content.id);
    }
  }

  /// Retry loading content after error
  Future<void> retryLoading() async {
    final currentState = state;
    if (currentState is DetailError && currentState.contentId != null) {
      logInfo('Retrying content load');
      await loadContentDetail(currentState.contentId!);
    }
  }

  /// Update content in current state (for external updates)
  void updateContent(Content updatedContent) {
    final currentState = state;
    if (currentState is DetailLoaded &&
        currentState.content.id == updatedContent.id) {
      logInfo('Updating content in detail state');
      emit(currentState.copyWith(
        content: updatedContent,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  /// Check if content is favorited
  Future<bool> _checkIfFavorited(String contentId, {String? sourceId}) async {
    try {
      return await _userDataRepository.isFavorite(
        contentId,
        sourceId: sourceId,
      );
    } catch (e) {
      logWarning('Failed to check favorite status: ${e.toString()}');
      return false;
    }
  }

  /// Add content to favorites
  Future<void> _addToFavorites(Content content) async {
    try {
      final params = AddToFavoritesParams.create(content);
      await _addToFavoritesUseCase(params);
      logDebug('Added to favorites: ${content.title}');
    } catch (e) {
      throw Exception('Failed to add to favorites: ${e.toString()}');
    }
  }

  /// Remove content from favorites
  Future<void> _removeFromFavorites(String contentId,
      {String? sourceId}) async {
    try {
      final params = RemoveFromFavoritesParams.fromString(
        contentId,
        sourceId: sourceId,
      );
      await _removeFromFavoritesUseCase(params);
      logDebug('Removed from favorites: $contentId');
    } catch (e) {
      throw Exception('Failed to remove from favorites: ${e.toString()}');
    }
  }

  /// Get current content
  Content? get currentContent {
    final currentState = state;
    if (currentState is DetailLoaded) {
      return currentState.content;
    }
    return null;
  }

  /// Check if current content is favorited
  bool get isFavorited {
    final currentState = state;
    if (currentState is DetailLoaded) {
      return currentState.isFavorited;
    }
    return false;
  }

  /// Generate image metadata for content
  /// Returns null if generation fails (with timeout and error handling)
  Future<List<ImageMetadata>?> generateImageMetadata(
      String contentId, List<String> imageUrls) async {
    try {
      logInfo(
          'Generating image metadata for content: $contentId (${imageUrls.length} images)');

      // Generate metadata with timeout to prevent blocking UI
      final metadata = await _imageMetadataService
          .generateMetadataBatch(
        imageUrls: imageUrls,
        contentId: contentId,
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          logWarning('Metadata generation timed out for content: $contentId');
          return [];
        },
      );

      logInfo(
          'Successfully generated ${metadata.length} metadata entries for content: $contentId');
      return metadata;
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'generate image metadata');
      logWarning(
          'Failed to generate metadata for content: $contentId, error: ${e.toString()}');
      return null; // Return null on error to allow fallback to raw URLs
    }
  }

  /// Open a specific chapter
  Future<void> openChapter(Chapter chapter) async {
    final currentState = state;
    if (currentState is! DetailLoaded) return;

    // Prevent double opening
    if (currentState is DetailOpeningChapter) return;

    try {
      logInfo('Opening chapter: ${chapter.title} (${chapter.id})');
      emit(DetailOpeningChapter(
        content: currentState.content,
        isFavorited: currentState.isFavorited,
        lastUpdated: currentState.lastUpdated,
        imageMetadata: currentState.imageMetadata,
        chapterHistory: currentState.chapterHistory,
      ));

      final source =
          _contentSourceRegistry.getSource(currentState.content.sourceId);

      List<String> images = [];
      ChapterData? chapterData;

      // 🚀 OFFLINE-FIRST: Check if chapter is available offline
      final isOfflineAvailable =
          await _offlineContentManager.isContentAvailableOffline(chapter.id);

      if (isOfflineAvailable) {
        logInfo(
            'Chapter ${chapter.id} found offline, loading from local storage');
        images = await _offlineContentManager.getOfflineImageUrls(chapter.id);

        if (images.isNotEmpty) {
          logInfo('✅ Loaded ${images.length} images from offline storage');
        } else {
          logWarning('⚠️ Offline chapter directory exists but no images found');
        }
      }

      // Fallback to online API if offline content not available or failed
      if (images.isEmpty) {
        logInfo('📡 Fetching chapter from online API');

        if (source != null) {
          chapterData = await source.getChapterImages(chapter.id);
          if (chapterData != null) {
            images = chapterData.images;
          } else {
            logWarning(
                'Source ${source.displayName} returned null chapter data or does not support getChapterImages');
          }
        } else {
          logWarning('Source is null, cannot fetch chapter images directly');
        }
      }

      if (isClosed) return;

      if (images.isEmpty) {
        // Use ActionFailure to preserve UI instead of replacing with Error screen
        String message = 'Failed to load chapter images';
        bool needsLogin = false;

        // Crotpedia specific heuristic (Generic source might need its own heuristic later)
        if (currentState.content.sourceId == 'crotpedia') {
          message = 'This chapter requires login or is unavailable.';
          needsLogin = true;
        }
        emit(DetailActionFailure(
          message: message,
          content: currentState.content,
          isFavorited: currentState.isFavorited,
          lastUpdated: currentState.lastUpdated,
          imageMetadata: currentState.imageMetadata,
          chapterHistory: currentState.chapterHistory,
          needsLogin: needsLogin,
        ));

        // Return to clean state so subsequent clicks work even if error repeats
        emit(currentState);
        return;
      }

      // Create a temporary Content object for the Reader
      // KEEP the original content ID (Series ID) so history/settings work correctly
      final chapterContent = currentState.content.copyWith(
        title: '${currentState.content.title} - ${chapter.title}',
        imageUrls: images,
        pageCount: images.length,
        chapters: null,
      );

      emit(DetailReaderReady(
        chapterContent: chapterContent,
        content: currentState.content,
        isFavorited: currentState.isFavorited,
        lastUpdated: currentState.lastUpdated,
        imageMetadata: currentState.imageMetadata,
        chapterHistory: currentState.chapterHistory,
        chapterData: chapterData,
        currentChapter: chapter, // Add this field to DetailReaderReady state
      ));
    } catch (e) {
      logger.e('Failed to open chapter: $e');
      final message = ErrorMessageUtils.getFriendlyErrorMessage(e);

      emit(DetailActionFailure(
        message: 'failedOpenChapter',
        content: currentState.content,
        isFavorited: currentState.isFavorited,
        lastUpdated: currentState.lastUpdated,
        imageMetadata: currentState.imageMetadata,
        chapterHistory: currentState.chapterHistory,
        error: e,
      ));
    }
  }

  /// Reset state after navigation
  void resetToLoaded() {
    final currentState = state;
    if (currentState is DetailReaderReady) {
      emit(DetailLoaded(
        content: currentState.content,
        isFavorited: currentState.isFavorited,
        lastUpdated: currentState.lastUpdated,
        imageMetadata: currentState.imageMetadata,
        chapterHistory: currentState.chapterHistory,
      ));
    } else if (currentState is DetailActionFailure) {
      emit(DetailLoaded(
        content: currentState.content,
        isFavorited: currentState.isFavorited,
        lastUpdated: currentState.lastUpdated,
        imageMetadata: currentState.imageMetadata,
        chapterHistory: currentState.chapterHistory,
      ));
    }
  }

  /// Refresh chapter history from database
  /// Call this when returning from reader to update read indicators
  Future<void> refreshChapterHistory() async {
    final currentState = state;
    if (currentState is! DetailLoaded) {
      logWarning('Cannot refresh chapter history: content not loaded');
      return;
    }

    try {
      logInfo('Refreshing chapter history for: ${currentState.content.id}');

      final chapterHistoryList = await _userDataRepository
          .getAllChapterHistory(currentState.content.id);
      final chapterHistory = {
        for (var history in chapterHistoryList) history.chapterId!: history
      };

      if (isClosed) return;

      emit(currentState.copyWith(
        chapterHistory: chapterHistory,
        lastUpdated: DateTime.now(),
      ));

      logInfo('Chapter history refreshed: ${chapterHistory.length} entries');
    } catch (e) {
      logWarning('Failed to refresh chapter history: $e');
      // Don't emit error, just keep current state
    }
  }
}
