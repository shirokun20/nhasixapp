/// Constants for notification service
///
/// Contains channel IDs, action IDs, and default values
/// used across notification handlers.
library;

/// Notification Channel Configuration
class NotificationChannels {
  NotificationChannels._();

  /// Download notification channel
  static const String downloadChannelId = 'download_channel';
  static const String downloadChannelName = 'Downloads';
  static const String downloadChannelDescription =
      'Download progress and status notifications';

  /// PDF conversion notification channel
  static const String pdfChannelId = 'pdf_conversion_channel';
  static const String pdfChannelName = 'PDF Conversion';
  static const String pdfChannelDescription =
      'PDF conversion progress notifications';

  /// General notification channel
  static const String generalChannelId = 'general_channel';
  static const String generalChannelName = 'General';
  static const String generalChannelDescription = 'General app notifications';
}

/// Notification Action IDs
///
/// These IDs are used to identify which action button was pressed
/// in a notification.
class NotificationActions {
  NotificationActions._();

  // Download actions
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String cancel = 'cancel';
  static const String retry = 'retry';
  static const String open = 'open';

  // PDF actions
  static const String openPdf = 'open_pdf';
  static const String sharePdf = 'share_pdf';
  static const String retryPdf = 'retry_pdf';
}

/// Notification ID Ranges
///
/// Separates notification types by ID range to avoid conflicts.
class NotificationIdRanges {
  NotificationIdRanges._();

  /// Base ID for download notifications (0-99999)
  static const int downloadBase = 0;

  /// Base ID for PDF notifications (100000-199999)
  static const int pdfBase = 100000;

  /// Base ID for general notifications (200000+)
  static const int generalBase = 200000;

  /// Test notification ID
  static const int testNotificationId = 999999;
}

/// Notification Display Limits
class NotificationLimits {
  NotificationLimits._();

  /// Maximum title length before truncation
  static const int maxTitleLength = 40;

  /// Maximum error message length before truncation
  static const int maxErrorLength = 100;

  /// Progress update interval (only update every N percent)
  static const int progressUpdateInterval = 10;
}

/// Notification Payload Keys
class NotificationPayloadKeys {
  NotificationPayloadKeys._();

  static const String contentId = 'contentId';
  static const String action = 'action';
  static const String pdfPath = 'pdfPath';
  static const String type = 'type';

  // Type values
  static const String typeDownload = 'download';
  static const String typePdf = 'pdf';
}
