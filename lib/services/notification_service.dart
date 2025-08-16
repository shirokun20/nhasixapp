import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

/// Service untuk handle local notifications untuk download
class NotificationService {
  NotificationService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Notification channels
  static const String _downloadChannelId = 'download_channel';
  static const String _downloadChannelName = 'Downloads';
  static const String _downloadChannelDescription =
      'Download progress notifications';

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Android initialization
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      _logger.i('NotificationService initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize NotificationService: $e');
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _downloadChannelId,
      _downloadChannelName,
      description: _downloadChannelDescription,
      importance: Importance.low, // Low importance for progress notifications
      enableVibration: false,
      playSound: false,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.d('Notification tapped: ${response.payload}');

    // Handle different notification actions
    switch (response.actionId) {
      case 'pause':
        _logger.d('Pause action tapped for: ${response.payload}');
        // TODO: Implement pause action
        break;
      case 'resume':
        _logger.d('Resume action tapped for: ${response.payload}');
        // TODO: Implement resume action
        break;
      case 'cancel':
        _logger.d('Cancel action tapped for: ${response.payload}');
        // TODO: Implement cancel action
        break;
      case 'open':
        _logger.d('Open action tapped for: ${response.payload}');
        // TODO: Implement open downloaded content
        break;
      default:
        _logger.d('Default notification tap for: ${response.payload}');
        // TODO: Navigate to downloads screen
        break;
    }
  }

  /// Show download started notification
  Future<void> showDownloadStarted({
    required String contentId,
    required String title,
  }) async {
    try {
      final notificationId = _getNotificationId(contentId);

      await _notificationsPlugin.show(
        notificationId,
        'Download Started',
        'Downloading: ${_truncateTitle(title)}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _downloadChannelId,
            _downloadChannelName,
            channelDescription: _downloadChannelDescription,
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            showProgress: true,
            maxProgress: 100,
            progress: 0,
            // Remove actions to avoid drawable resource errors
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: false,
            presentSound: false,
          ),
        ),
        payload: contentId,
      );

      _logger.d('Download started notification shown for: $contentId');
    } catch (e) {
      _logger.e('Failed to show download started notification: $e');
    }
  }

  /// Update download progress notification
  Future<void> updateDownloadProgress({
    required String contentId,
    required int progress,
    required String title,
    bool isPaused = false,
  }) async {
    try {
      final notificationId = _getNotificationId(contentId);
      final statusText = isPaused ? 'Paused' : 'Downloading';

      await _notificationsPlugin.show(
        notificationId,
        '$statusText ($progress%)',
        _truncateTitle(title),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _downloadChannelId,
            _downloadChannelName,
            channelDescription: _downloadChannelDescription,
            importance: Importance.low,
            priority: Priority.low,
            ongoing: !isPaused,
            autoCancel: false,
            showProgress: true,
            maxProgress: 100,
            progress: progress,
            // Remove actions to avoid drawable resource errors
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: false,
            presentSound: false,
          ),
        ),
        payload: contentId,
      );

      // Log progress every 10%
      if (progress % 10 == 0) {
        _logger.d('Download progress updated: $contentId - $progress%');
      }
    } catch (e) {
      _logger.e('Failed to update download progress notification: $e');
    }
  }

  /// Show download completed notification
  Future<void> showDownloadCompleted({
    required String contentId,
    required String title,
    required String downloadPath,
  }) async {
    try {
      final notificationId = _getNotificationId(contentId);

      await _notificationsPlugin.show(
        notificationId,
        'Download Complete',
        'Downloaded: ${_truncateTitle(title)}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _downloadChannelId,
            _downloadChannelName,
            channelDescription: _downloadChannelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            ongoing: false,
            autoCancel: true,
            // Remove actions to avoid drawable resource errors
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: contentId,
      );

      _logger.i('Download completed notification shown for: $contentId');
    } catch (e) {
      _logger.e('Failed to show download completed notification: $e');
    }
  }

  /// Show download error notification
  Future<void> showDownloadError({
    required String contentId,
    required String title,
    required String error,
  }) async {
    try {
      final notificationId = _getNotificationId(contentId);

      await _notificationsPlugin.show(
        notificationId,
        'Download Failed',
        'Failed: ${_truncateTitle(title)}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _downloadChannelId,
            _downloadChannelName,
            channelDescription: _downloadChannelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            ongoing: false,
            autoCancel: true,
            styleInformation: BigTextStyleInformation(
              'Download failed: ${_truncateError(error)}',
              contentTitle: 'Download Failed',
              summaryText: _truncateTitle(title),
            ),
            // Remove actions to avoid drawable resource errors
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: contentId,
      );

      _logger.w('Download error notification shown for: $contentId - $error');
    } catch (e) {
      _logger.e('Failed to show download error notification: $e');
    }
  }

  /// Show download paused notification
  Future<void> showDownloadPaused({
    required String contentId,
    required String title,
    required int progress,
  }) async {
    await updateDownloadProgress(
      contentId: contentId,
      progress: progress,
      title: title,
      isPaused: true,
    );
  }

  /// Cancel download notification
  Future<void> cancelDownloadNotification(String contentId) async {
    try {
      final notificationId = _getNotificationId(contentId);
      await _notificationsPlugin.cancel(notificationId);

      _logger.d('Download notification cancelled for: $contentId');
    } catch (e) {
      _logger.e('Failed to cancel download notification: $e');
    }
  }

  /// Cancel all download notifications
  Future<void> cancelAllDownloadNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      _logger.d('All download notifications cancelled');
    } catch (e) {
      _logger.e('Failed to cancel all download notifications: $e');
    }
  }

  /// Get notification ID from content ID
  int _getNotificationId(String contentId) {
    // Convert content ID to integer for notification ID
    // Use hashCode to ensure consistent ID for same content
    return contentId.hashCode.abs() % 2147483647; // Max int32 value
  }

  /// Truncate title for notification display
  String _truncateTitle(String title, {int maxLength = 40}) {
    if (title.length <= maxLength) return title;
    return '${title.substring(0, maxLength - 3)}...';
  }

  /// Truncate error message for notification display
  String _truncateError(String error, {int maxLength = 100}) {
    if (error.length <= maxLength) return error;
    return '${error.substring(0, maxLength - 3)}...';
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        return await androidImplementation.areNotificationsEnabled() ?? false;
      }

      return true; // Assume enabled for other platforms
    } catch (e) {
      _logger.e('Failed to check notification permissions: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        return await androidImplementation.requestNotificationsPermission() ??
            false;
      }

      return true; // Assume granted for other platforms
    } catch (e) {
      _logger.e('Failed to request notification permissions: $e');
      return false;
    }
  }
}
