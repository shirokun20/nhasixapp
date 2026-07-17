import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_constants.dart';

/// Builder class for creating NotificationDetails with common configurations
///
/// This reduces duplication in NotificationService by providing factory methods
/// for common notification types.
class NotificationDetailsBuilder {
  NotificationDetailsBuilder._();

  /// Build details for progress notifications (downloads, PDF conversion)
  static NotificationDetails progress({
    required int progress,
    int maxProgress = 100,
    bool ongoing = true,
    bool autoCancel = false,
    bool indeterminate = false,
    bool highPriority = false, // NEW: For initial notifications with sound
    bool playSound = false, // NEW: Enable sound for initial notifications
    bool enableVibration = false, // NEW: Enable vibration
    List<AndroidNotificationAction>? actions,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.downloadChannelId,
        NotificationChannels.downloadChannelName,
        channelDescription: NotificationChannels.downloadChannelDescription,
        importance: highPriority ? Importance.high : Importance.low,
        priority: highPriority ? Priority.high : Priority.low,
        ongoing: ongoing,
        autoCancel: autoCancel,
        showProgress: true,
        indeterminate: indeterminate,
        maxProgress: maxProgress,
        progress: progress,
        playSound: playSound,
        enableVibration: enableVibration,
        actions: actions,
      ),
    );
  }

  /// Build details for success notifications (completed downloads, PDF ready)
  static NotificationDetails success({
    String? summaryText,
    String? bigText,
    String? contentTitle,
    List<AndroidNotificationAction>? actions,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.downloadChannelId,
        NotificationChannels.downloadChannelName,
        channelDescription: NotificationChannels.downloadChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        showProgress: false,
        actions: actions,
        styleInformation: bigText != null
            ? BigTextStyleInformation(
                bigText,
                contentTitle: contentTitle,
                summaryText: summaryText,
              )
            : null,
      ),
    );
  }

  /// Build details for error notifications
  static NotificationDetails error({
    String? summaryText,
    String? bigText,
    String? contentTitle,
    List<AndroidNotificationAction>? actions,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.downloadChannelId,
        NotificationChannels.downloadChannelName,
        channelDescription: NotificationChannels.downloadChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        showProgress: false,
        actions: actions,
        styleInformation: bigText != null
            ? BigTextStyleInformation(
                bigText,
                contentTitle: contentTitle,
                summaryText: summaryText,
              )
            : null,
      ),
    );
  }

  /// Build details for paused notifications
  static NotificationDetails paused({
    required int progress,
    List<AndroidNotificationAction>? actions,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.downloadChannelId,
        NotificationChannels.downloadChannelName,
        channelDescription: NotificationChannels.downloadChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showProgress: true,
        maxProgress: 100,
        progress: progress,
        actions: actions,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      ),
    );
  }

  /// Common action buttons for downloads
  static List<AndroidNotificationAction> downloadInProgressActions() {
    return const [
      AndroidNotificationAction(
        NotificationActions.pause,
        'Pause',
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        NotificationActions.cancel,
        'Cancel',
        showsUserInterface: false,
      ),
    ];
  }

  /// Common action buttons for paused downloads
  static List<AndroidNotificationAction> downloadPausedActions() {
    return const [
      AndroidNotificationAction(
        NotificationActions.resume,
        'Resume',
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        NotificationActions.cancel,
        'Cancel',
        showsUserInterface: false,
      ),
    ];
  }

  /// Common action buttons for completed downloads
  static List<AndroidNotificationAction> downloadCompletedActions() {
    return const [
      AndroidNotificationAction(
        NotificationActions.open,
        'Open',
        showsUserInterface: true,
      ),
    ];
  }

  /// Common action buttons for failed downloads
  static List<AndroidNotificationAction> downloadErrorActions() {
    return const [
      AndroidNotificationAction(
        NotificationActions.retry,
        'Retry',
        showsUserInterface: false,
      ),
    ];
  }

  /// Common action buttons for completed PDF
  static List<AndroidNotificationAction> pdfCompletedActions() {
    return const [
      AndroidNotificationAction(
        NotificationActions.openPdf,
        'Open PDF',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        NotificationActions.sharePdf,
        'Share',
        showsUserInterface: true,
      ),
    ];
  }

  /// Common action buttons for failed PDF conversion
  static List<AndroidNotificationAction> pdfErrorActions() {
    return const [
      AndroidNotificationAction(
        NotificationActions.retryPdf,
        'Retry',
        showsUserInterface: false,
      ),
    ];
  }
}
