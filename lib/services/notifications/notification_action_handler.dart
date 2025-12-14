import 'dart:io';

import 'package:logger/logger.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import 'notification_constants.dart';

/// Handles notification action responses
///
/// Extracted from NotificationService to improve code organization
/// and testability.
class NotificationActionHandler {
  NotificationActionHandler({
    required Logger logger,
    this.onDownloadPause,
    this.onDownloadResume,
    this.onDownloadCancel,
    this.onDownloadRetry,
    this.onPdfRetry,
    this.onOpenDownload,
    this.onNavigateToDownloads,
  }) : _logger = logger;

  final Logger _logger;

  // Callback functions for handling notification actions
  void Function(String contentId)? onDownloadPause;
  void Function(String contentId)? onDownloadResume;
  void Function(String contentId)? onDownloadCancel;
  void Function(String contentId)? onDownloadRetry;
  void Function(String contentId)? onPdfRetry;
  void Function(String contentId)? onOpenDownload;
  void Function(String? contentId)? onNavigateToDownloads;

  /// Set callbacks after initialization
  void setCallbacks({
    void Function(String contentId)? onDownloadPause,
    void Function(String contentId)? onDownloadResume,
    void Function(String contentId)? onDownloadCancel,
    void Function(String contentId)? onDownloadRetry,
    void Function(String contentId)? onPdfRetry,
    void Function(String contentId)? onOpenDownload,
    void Function(String? contentId)? onNavigateToDownloads,
  }) {
    if (onDownloadPause != null) this.onDownloadPause = onDownloadPause;
    if (onDownloadResume != null) this.onDownloadResume = onDownloadResume;
    if (onDownloadCancel != null) this.onDownloadCancel = onDownloadCancel;
    if (onDownloadRetry != null) this.onDownloadRetry = onDownloadRetry;
    if (onPdfRetry != null) this.onPdfRetry = onPdfRetry;
    if (onOpenDownload != null) this.onOpenDownload = onOpenDownload;
    if (onNavigateToDownloads != null) {
      this.onNavigateToDownloads = onNavigateToDownloads;
    }
  }

  /// Handle notification action based on action ID
  ///
  /// Returns true if the action was handled, false otherwise.
  /// [onCancelNotification] callback is called when download is cancelled.
  bool handleAction({
    required String? actionId,
    required String? payload,
    void Function(String contentId)? onCancelNotification,
  }) {
    _logger.i(
        '🔔 Notification action! ActionId: "$actionId", Payload: "$payload"');

    switch (actionId) {
      case NotificationActions.pause:
        return _handlePause(payload);

      case NotificationActions.resume:
        return _handleResume(payload);

      case NotificationActions.cancel:
        return _handleCancel(payload, onCancelNotification);

      case NotificationActions.retry:
        return _handleRetryDownload(payload);

      case NotificationActions.open:
        return _handleOpenDownload(payload);

      case NotificationActions.openPdf:
        _openPdfFile(payload);
        return true;

      case NotificationActions.sharePdf:
        _sharePdfFile(payload);
        return true;

      case NotificationActions.retryPdf:
        return _handleRetryPdf(payload);

      case null:
        return _handleDefaultTap(payload);

      default:
        _logger.w('⚠️ Unknown action: "$actionId" for: $payload');
        return false;
    }
  }

  bool _handlePause(String? payload) {
    _logger.i('⏸️ Pause action for: $payload');
    if (payload != null && onDownloadPause != null) {
      try {
        onDownloadPause!(payload);
        _logger.i('✅ Download pause triggered for: $payload');
        return true;
      } catch (e) {
        _logger.e('❌ Error pausing download: $e');
      }
    } else {
      _logger.w('⚠️ Cannot pause: payload is null or callback not set');
    }
    return false;
  }

  bool _handleResume(String? payload) {
    _logger.i('▶️ Resume action for: $payload');
    if (payload != null && onDownloadResume != null) {
      try {
        onDownloadResume!(payload);
        _logger.i('✅ Download resume triggered for: $payload');
        return true;
      } catch (e) {
        _logger.e('❌ Error resuming download: $e');
      }
    } else {
      _logger.w('⚠️ Cannot resume: payload is null or callback not set');
    }
    return false;
  }

  bool _handleCancel(
    String? payload,
    void Function(String)? onCancelNotification,
  ) {
    _logger.i('❌ Cancel action for: $payload');
    if (payload != null && onDownloadCancel != null) {
      try {
        onDownloadCancel!(payload);
        _logger.i('✅ Download cancel triggered for: $payload');
        // Also cancel the notification
        onCancelNotification?.call(payload);
        return true;
      } catch (e) {
        _logger.e('❌ Error cancelling download: $e');
      }
    } else {
      _logger.w('⚠️ Cannot cancel: payload is null or callback not set');
    }
    return false;
  }

  bool _handleRetryDownload(String? payload) {
    _logger.i('🔄 Retry download action for: $payload');
    if (payload != null && onDownloadRetry != null) {
      try {
        onDownloadRetry!(payload);
        _logger.i('✅ Download retry triggered for: $payload');
        return true;
      } catch (e) {
        _logger.e('❌ Error retrying download: $e');
      }
    } else {
      _logger.w('⚠️ Cannot retry: payload is null or callback not set');
    }
    return false;
  }

  bool _handleOpenDownload(String? payload) {
    _logger.i('📂 Open downloaded content action for: $payload');
    if (payload != null && onOpenDownload != null) {
      try {
        onOpenDownload!(payload);
        _logger.i('✅ Open download triggered for: $payload');
        return true;
      } catch (e) {
        _logger.e('❌ Error opening download: $e');
      }
    } else {
      _logger.w('⚠️ Cannot open: payload is null or callback not set');
    }
    return false;
  }

  bool _handleRetryPdf(String? payload) {
    _logger.i('🔄 Retry PDF conversion action for: $payload');
    if (payload != null && onPdfRetry != null) {
      try {
        onPdfRetry!(payload);
        _logger.i('✅ PDF retry triggered for: $payload');
        return true;
      } catch (e) {
        _logger.e('❌ Error retrying PDF conversion: $e');
      }
    } else {
      _logger.w('⚠️ Cannot retry PDF: payload is null or callback not set');
    }
    return false;
  }

  bool _handleDefaultTap(String? payload) {
    _logger.i('📱 Default notification body tapped for: $payload');
    // Check if payload is a PDF file path and open it
    if (payload != null && payload.endsWith('.pdf')) {
      _logger.i('📂 Opening PDF from default tap: $payload');
      _openPdfFile(payload);
      return true;
    } else {
      // Navigate to downloads screen
      _logger.i('📱 Navigating to downloads screen for: $payload');
      if (onNavigateToDownloads != null) {
        try {
          onNavigateToDownloads!(payload);
          _logger.i('✅ Navigation to downloads screen triggered');
          return true;
        } catch (e) {
          _logger.e('❌ Error navigating to downloads screen: $e');
        }
      } else {
        _logger.w('⚠️ Cannot navigate: callback not set');
      }
    }
    return false;
  }

  /// Open PDF file using system default app
  Future<void> _openPdfFile(String? filePath) async {
    _logger.i('🔍 _openPdfFile called with: "$filePath"');

    if (filePath == null || filePath.isEmpty) {
      _logger.w('❌ Cannot open PDF: file path is null or empty');
      return;
    }

    try {
      final file = File(filePath);
      _logger.i('📁 Checking if file exists: ${file.path}');

      if (!await file.exists()) {
        _logger.w('❌ Cannot open PDF: file does not exist at $filePath');
        return;
      }

      _logger.i('✅ File exists, attempting to open: $filePath');
      final result = await OpenFile.open(filePath);

      switch (result.type) {
        case ResultType.done:
          _logger.i('✅ PDF opened successfully: $filePath');
          break;
        case ResultType.fileNotFound:
          _logger.w('❌ PDF file not found: $filePath');
          break;
        case ResultType.noAppToOpen:
          _logger.w('❌ No app available to open PDF: $filePath');
          break;
        case ResultType.permissionDenied:
          _logger.w('❌ Permission denied to open PDF: $filePath');
          break;
        case ResultType.error:
          _logger.e('❌ Error opening PDF: ${result.message}');
          break;
      }
    } catch (e) {
      _logger.e('💥 Exception opening PDF file: $e');
    }
  }

  /// Share PDF file using system share sheet
  Future<void> _sharePdfFile(String? filePath) async {
    _logger.i('📤 _sharePdfFile called with: "$filePath"');

    if (filePath == null || filePath.isEmpty) {
      _logger.w('❌ Cannot share PDF: file path is null or empty');
      return;
    }

    try {
      final file = File(filePath);
      _logger.i('📁 Checking if file exists: ${file.path}');

      if (!await file.exists()) {
        _logger.w('❌ Cannot share PDF: file does not exist at $filePath');
        return;
      }

      _logger.i('✅ File exists, attempting to share: $filePath');
      final xFile = XFile(filePath);
      await SharePlus.instance.share(
        ShareParams(
          text: 'Sharing PDF document',
          subject: 'PDF Document',
          files: [xFile],
        ),
      );

      _logger.i('✅ PDF shared successfully: $filePath');
    } catch (e) {
      _logger.e('💥 Exception sharing PDF file: $e');
    }
  }
}
