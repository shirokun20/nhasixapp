import 'package:flutter/services.dart';

class NativeDownloadService {
  static const MethodChannel _channel = MethodChannel('id.nhasix.app/download');
  static const EventChannel _progressChannel = EventChannel('id.nhasix.app/download_progress');

  Stream<Map<String, dynamic>>? _progressStream;

  /// Start download via native layer
  Future<String> startDownload({
    required String contentId,
    required String sourceId,
    required List<String> imageUrls,
    required String destinationPath,
  }) async {
    try {
      final workId = await _channel.invokeMethod<String>('startDownload', {
        'contentId': contentId,
        'sourceId': sourceId,
        'imageUrls': imageUrls,
        'destinationPath': destinationPath,
      });
      return workId ?? '';
    } on PlatformException catch (e) {
      throw Exception('Failed to start native download: ${e.message}');
    }
  }

  Future<void> cancelDownload(String contentId) async {
    try {
      await _channel.invokeMethod('cancelDownload', {'contentId': contentId});
    } on PlatformException catch (e) {
      throw Exception('Failed to cancel native download: ${e.message}');
    }
  }

  Future<void> pauseDownload(String contentId) async {
    try {
      await _channel.invokeMethod('pauseDownload', {'contentId': contentId});
    } on PlatformException catch (e) {
      throw Exception('Failed to pause native download: ${e.message}');
    }
  }

  Future<Map<String, dynamic>?> getDownloadStatus(String contentId) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getDownloadStatus',
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
}
