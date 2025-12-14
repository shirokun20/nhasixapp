import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

/// Standalone download utilities for background worker
///
/// These functions are designed to work in a background isolate
/// without access to DI or Flutter framework.
///
/// Note: This is a lightweight version for background downloads.
/// For full download with notifications, use DownloadService instead.
class BackgroundDownloadUtils {
  BackgroundDownloadUtils._();

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 30),
  ));

  /// Download a single image from URL to file path
  ///
  /// Returns true if successful, false otherwise.
  static Future<bool> downloadImage({
    required String imageUrl,
    required String filePath,
    CancelToken? cancelToken,
  }) async {
    try {
      final file = File(filePath);

      // Skip if file already exists and has content
      if (await file.exists()) {
        final size = await file.length();
        if (size > 0) {
          return true;
        }
      }

      // Create parent directories
      await file.parent.create(recursive: true);

      // Download with retry
      const maxRetries = 3;
      for (var attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final response = await _dio.get<List<int>>(
            imageUrl,
            options: Options(
              responseType: ResponseType.bytes,
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept': 'image/*',
                'Referer': 'https://nhentai.net/',
              },
            ),
            cancelToken: cancelToken,
          );

          if (response.statusCode == 200 && response.data != null) {
            await file.writeAsBytes(response.data!);
            return true;
          }
        } catch (e) {
          if (attempt == maxRetries) rethrow;
          await Future.delayed(Duration(seconds: attempt * 2)); // Backoff
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Download multiple images for a content
  ///
  /// Parameters:
  /// - [contentId]: ID of the content
  /// - [imageUrls]: List of image URLs to download
  /// - [savePath]: Base path to save files
  /// - [startIndex]: Index to start from (for resume)
  /// - [onProgress]: Progress callback (index, total)
  ///
  /// Returns number of successfully downloaded images.
  static Future<int> downloadImages({
    required String contentId,
    required List<String> imageUrls,
    required String savePath,
    int startIndex = 0,
    void Function(int current, int total)? onProgress,
  }) async {
    int successCount = 0;
    final total = imageUrls.length;

    for (var i = startIndex; i < total; i++) {
      final url = imageUrls[i];
      final fileName = '${(i + 1).toString().padLeft(4, '0')}.jpg';
      final filePath = '$savePath/$fileName';

      final success = await downloadImage(
        imageUrl: url,
        filePath: filePath,
      );

      if (success) {
        successCount++;
        // Save progress periodically
        if (successCount % 5 == 0) {
          await saveProgress(contentId, i + 1, total);
        }
      }

      onProgress?.call(i + 1, total);
    }

    // Final progress save
    await saveProgress(contentId, total, total);

    return successCount;
  }

  /// Save download progress to SharedPreferences
  static Future<void> saveProgress(
    String contentId,
    int current,
    int total,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bg_download_progress_$contentId', current);
    await prefs.setInt('bg_download_total_$contentId', total);
    await prefs.setString(
        'bg_download_time_$contentId', DateTime.now().toIso8601String());
  }

  /// Get saved download progress
  static Future<int> getProgress(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('bg_download_progress_$contentId') ?? 0;
  }

  /// Mark download as complete
  static Future<void> markComplete(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bg_download_complete_$contentId', true);

    // Add to complete list
    final completeList =
        prefs.getStringList('bg_downloads_complete') ?? <String>[];
    if (!completeList.contains(contentId)) {
      completeList.add(contentId);
      await prefs.setStringList('bg_downloads_complete', completeList);
    }

    // Remove from incomplete list
    final incompleteList =
        prefs.getStringList('incomplete_downloads') ?? <String>[];
    incompleteList.remove(contentId);
    await prefs.setStringList('incomplete_downloads', incompleteList);
  }

  /// Mark download as incomplete (for resume later)
  static Future<void> markIncomplete(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    final incompleteList =
        prefs.getStringList('incomplete_downloads') ?? <String>[];
    if (!incompleteList.contains(contentId)) {
      incompleteList.add(contentId);
      await prefs.setStringList('incomplete_downloads', incompleteList);
    }
  }

  /// Get list of incomplete downloads
  static Future<List<String>> getIncompleteDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('incomplete_downloads') ?? [];
  }

  /// Save download state for resumption
  static Future<void> saveResumeState(
    String contentId, {
    required String downloadUrl,
    required String savePath,
    required String title,
    required int totalImages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'contentId': contentId,
      'downloadUrl': downloadUrl,
      'savePath': savePath,
      'title': title,
      'totalImages': totalImages,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('resume_state_$contentId', jsonEncode(data));
  }

  /// Load download state for resumption
  static Future<Map<String, dynamic>?> loadResumeState(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString('resume_state_$contentId');
    if (dataStr != null) {
      return jsonDecode(dataStr) as Map<String, dynamic>;
    }
    return null;
  }

  /// Clear resume state
  static Future<void> clearResumeState(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('resume_state_$contentId');
  }

  /// Clear download state & resume state
  static Future<void> clearState(String contentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bg_download_progress_$contentId');
    await prefs.remove('bg_download_total_$contentId');
    await prefs.remove('bg_download_time_$contentId');
    await prefs.remove('bg_download_complete_$contentId');
    await prefs.remove('resume_state_$contentId');
  }

  /// Get app downloads directory path
  static Future<String> getDownloadsPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/Downloads';
  }

  /// Create content download directory
  static Future<String> createContentDirectory(String contentId) async {
    final basePath = await getDownloadsPath();
    final contentPath = '$basePath/$contentId';
    final dir = Directory(contentPath);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Create .nomedia file for privacy
    final nomediaFile = File('$contentPath/.nomedia');
    if (!await nomediaFile.exists()) {
      await nomediaFile.create();
    }

    return contentPath;
  }

  /// Save download metadata as JSON
  static Future<void> saveMetadata({
    required String contentId,
    required String title,
    required int totalImages,
    required String savePath,
    Map<String, dynamic>? extraData,
  }) async {
    final metadataPath = '$savePath/metadata.json';
    final metadata = {
      'contentId': contentId,
      'title': title,
      'totalImages': totalImages,
      'downloadedAt': DateTime.now().toIso8601String(),
      'source': 'background_worker',
      ...?extraData,
    };

    final file = File(metadataPath);
    await file.writeAsString(jsonEncode(metadata));
  }

  /// Read download metadata
  static Future<Map<String, dynamic>?> readMetadata(String savePath) async {
    try {
      final metadataPath = '$savePath/metadata.json';
      final file = File(metadataPath);

      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  /// Sync database with filesystem (remove entries for missing files)
  static Future<int> syncDatabaseFilesystem() async {
    try {
      final dbPath = await getDatabasesPath();
      final pathStr = path.join(dbPath, 'nhasix_app.db');

      // Open database directly since we are in background isolate
      final db = await openDatabase(pathStr, version: 1);

      // Get all completed downloads
      final List<Map<String, dynamic>> downloads = await db.query(
        'downloads',
        columns: ['id', 'download_path'],
        where: 'state = ?',
        whereArgs: ['completed'],
      );

      int removedCount = 0;

      for (final row in downloads) {
        final id = row['id'] as String;
        final downloadPath = row['download_path'] as String?;

        if (downloadPath == null || downloadPath.isEmpty) continue;

        final dir = Directory(downloadPath);
        if (!await dir.exists() || (await dir.list().isEmpty)) {
          // File missing, remove from DB
          await db.delete(
            'downloads',
            where: 'id = ?',
            whereArgs: [id],
          );
          removedCount++;
        }
      }

      await db.close();
      return removedCount;
    } catch (e) {
      // Log error but don't crash
      return 0;
    }
  }
}
