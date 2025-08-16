import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:equatable/equatable.dart';

import '../../../core/utils/offline_content_manager.dart';
import '../../../domain/entities/content.dart';
import '../base/base_cubit.dart';

part 'offline_search_state.dart';

/// Cubit for searching offline/downloaded content
class OfflineSearchCubit extends BaseCubit<OfflineSearchState> {
  OfflineSearchCubit({
    required OfflineContentManager offlineContentManager,
    required Logger logger,
  })  : _offlineContentManager = offlineContentManager,
        super(
          initialState: const OfflineSearchInitial(),
          logger: logger,
        );

  final OfflineContentManager _offlineContentManager;

  /// Search in offline content
  Future<void> searchOfflineContent(String query) async {
    try {
      if (query.trim().isEmpty) {
        emit(const OfflineSearchInitial());
        return;
      }

      logInfo('Searching offline content for: $query');
      emit(const OfflineSearchLoading());

      final matchingIds =
          await _offlineContentManager.searchOfflineContent(query);

      if (matchingIds.isEmpty) {
        emit(const OfflineSearchEmpty(query: ''));
        return;
      }

      // Create content objects for matching IDs
      final contents = <Content>[];
      for (final contentId in matchingIds) {
        final content =
            await _offlineContentManager.createOfflineContent(contentId);
        if (content != null) {
          contents.add(content);
        }
      }

      emit(OfflineSearchLoaded(
        query: query,
        results: contents,
        totalResults: contents.length,
      ));

      logInfo('Found ${contents.length} offline content matches for: $query');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'search offline content');
      emit(OfflineSearchError(
        message: 'Failed to search offline content: ${e.toString()}',
        query: query,
      ));
    }
  }

  /// Get all offline content
  Future<void> getAllOfflineContent() async {
    try {
      logInfo('Loading all offline content');
      emit(const OfflineSearchLoading());

      final offlineIds = await _offlineContentManager.getOfflineContentIds();

      if (offlineIds.isEmpty) {
        emit(const OfflineSearchEmpty(query: ''));
        return;
      }

      // Create content objects for all offline IDs
      final contents = <Content>[];
      for (final contentId in offlineIds) {
        final content =
            await _offlineContentManager.createOfflineContent(contentId);
        if (content != null) {
          contents.add(content);
        }
      }

      // Sort by most recently accessed (from history)
      contents.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));

      emit(OfflineSearchLoaded(
        query: '',
        results: contents,
        totalResults: contents.length,
      ));

      logInfo('Loaded ${contents.length} offline content items');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'get all offline content');
      emit(const OfflineSearchError(
        message: 'Failed to load offline content',
        query: '',
      ));
    }
  }

  /// Clear search results
  void clearSearch() {
    emit(const OfflineSearchInitial());
  }

  /// Get offline storage statistics
  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      final offlineIds = await _offlineContentManager.getOfflineContentIds();
      final storageUsage =
          await _offlineContentManager.getOfflineStorageUsage();

      return {
        'totalContent': offlineIds.length,
        'storageUsage': storageUsage,
        'formattedSize': OfflineContentManager.formatStorageSize(storageUsage),
      };
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'get offline stats');
      return {
        'totalContent': 0,
        'storageUsage': 0,
        'formattedSize': '0 B',
      };
    }
  }

  /// Cleanup orphaned offline files
  Future<void> cleanupOfflineFiles() async {
    try {
      logInfo('Starting cleanup of orphaned offline files');
      await _offlineContentManager.cleanupOrphanedFiles();
      logInfo('Cleanup completed successfully');
    } catch (e, stackTrace) {
      handleError(e, stackTrace, 'cleanup offline files');
      rethrow;
    }
  }
}
