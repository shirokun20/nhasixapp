import 'package:flutter/services.dart';

class NativeDownloadService {
  // Singleton pattern
  static final NativeDownloadService _instance = NativeDownloadService._internal();
  factory NativeDownloadService() => _instance;
  NativeDownloadService._internal();

  static const MethodChannel _channel = MethodChannel('kuron_native');
  static const EventChannel _progressChannel = EventChannel('kuron_native/download_progress');

  Stream<Map<String, dynamic>>? _progressStream;

  /// Start download via native layer
  Future<String> startDownload({
    required String contentId,
    required String sourceId,
    required List<String> imageUrls,
    required String destinationPath,
    String? backupFolderName, // NEW: Configurable folder name
    Map<String, String>? cookies,
    // Metadata v2.1 fields
    String? title,
    String? url,
    String? coverUrl,
    String? language,
    bool enableNotifications = true, // NEW
  }) async {
    try {
      final workId = await _channel.invokeMethod<String>('kuronNativeStartDownload', {
        'contentId': contentId,
        'sourceId': sourceId,
        'imageUrls': imageUrls,
        'destinationPath': destinationPath,
        'backupFolderName': backupFolderName, // NEW
        'cookies': cookies,
        // Metadata v2.1
        'title': title,
        'url': url,
        'coverUrl': coverUrl,
        'language': language,
        'enableNotifications': enableNotifications, // NEW
      });
      return workId ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to start native download: ${e.message}');
    }
  }

  Future<void> cancelDownload(String contentId) async {
    try {
      await _channel.invokeMethod('kuronNativeCancelDownload', {'contentId': contentId});
    } on PlatformException catch (e) {
      throw Exception('Failed to cancel native download: ${e.message}');
    }
  }

  Future<void> pauseDownload(String contentId) async {
    try {
      await _channel.invokeMethod('kuronNativePauseDownload', {'contentId': contentId});
    } on PlatformException catch (e) {
      throw Exception('Failed to pause native download: ${e.message}');
    }
  }

  Future<Map<String, dynamic>?> getDownloadStatus(String contentId) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'kuronNativeGetDownloadStatus',
        {'contentId': contentId},
      );
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to get download status: ${e.message}');
    }
  }

  /// Listen to download progress
  Stream<Map<String, dynamic>> getProgressStream() {
    _progressStream ??= _progressChannel
        .receiveBroadcastStream()
        .map((data) => Map<String, dynamic>.from(data as Map));
    return _progressStream!;
  }

  /// Get downloaded files for content
  Future<List<String>> getDownloadedFiles(String contentId) async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>('kuronNativeGetDownloadedFiles', {
        'contentId': contentId,
      });
      return result?.cast<String>() ?? [];
    } on PlatformException catch (e) {
      throw Exception('Failed to get downloaded files: ${e.message}');
    }
  }

  /// Get download directory path for content
  Future<String?> getDownloadPath(String contentId) async {
    try {
      return await _channel.invokeMethod<String>('kuronNativeGetDownloadPath', {
        'contentId': contentId,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to get download path: ${e.message}');
    }
  }

  /// Delete downloaded content by content ID
  Future<void> deleteDownloadedContent(String contentId, {String? dirPath}) async {
    try {
      await _channel.invokeMethod('kuronNativeDeleteDownloadedContent', {
        'contentId': contentId,
        'dirPath': dirPath,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to delete downloaded content: ${e.message}');
    }
  }

  /// Count downloaded files in folder
  Future<int> countDownloadedFiles(String contentId) async {
    try {
      final count = await _channel.invokeMethod<int>('kuronNativeCountDownloadedFiles', {
        'contentId': contentId,
      });
      return count ?? 0;
    } on PlatformException catch (e) {
      throw Exception('Failed to count downloaded files: ${e.message}');
    }
  }

  /// Check if content is downloaded
  Future<bool> isContentDownloaded(String contentId) async {
    try {
      final count = await countDownloadedFiles(contentId);
      return count > 0;
    } catch (e) {
      return false;
    }
  }
}
