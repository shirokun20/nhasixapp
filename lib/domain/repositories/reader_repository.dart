import '../entities/reader_position.dart';

/// Repository interface for managing reader position persistence
/// Provides methods to save, load, and manage reading progress
abstract class ReaderRepository {
  /// Save current reader position
  Future<void> saveReaderPosition(ReaderPosition position);
  
  /// Get reader position for specific content
  Future<ReaderPosition?> getReaderPosition(String contentId);
  
  /// Get all reader positions (recent first)
  Future<List<ReaderPosition>> getAllReaderPositions({
    int limit = 50,
    int page = 1,
  });
  
  /// Delete reader position for specific content
  Future<void> deleteReaderPosition(String contentId);
  
  /// Clear all reader positions
  Future<void> clearAllReaderPositions();
  
  /// Update reading time for content
  Future<void> updateReadingTime(String contentId, int additionalMinutes);
  
  /// Get recently read content IDs (for quick access)
  Future<List<String>> getRecentlyReadContentIds({int limit = 10});
  
  /// Check if content has saved reading position
  Future<bool> hasReaderPosition(String contentId);
  
  /// Update reader position (current page only)
  Future<void> updateReaderPage({
    required String contentId,
    required int currentPage,
    required int totalPages,
  });
}