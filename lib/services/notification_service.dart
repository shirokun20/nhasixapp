import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service untuk handle local notifications untuk download
class NotificationService {
  NotificationService({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  bool _permissionGranted = false;
  bool _initialized = false;

  // Notification channels
  static const String _downloadChannelId = 'download_channel';
  static const String _downloadChannelName = 'Downloads';
  static const String _downloadChannelDescription =
      'Download progress notifications';

  /// Request notification permission from user
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      
      if (status.isGranted) {
        _logger.i('NotificationService: Permission granted');
        return true;
      } else if (status.isDenied) {
        _logger.w('NotificationService: Permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        _logger.w('NotificationService: Permission permanently denied');
        // Could show dialog to open app settings
        return false;
      }
      
      return false;
    } catch (e) {
      _logger.e('NotificationService: Error requesting permission: $e');
      return false;
    }
  }

  /// Show PDF conversion started notification
  /// Displays a notification when PDF conversion begins
  Future<void> showPdfConversionStarted({
    required String contentId,
    required String title,
  }) async {
    if (!isEnabled) return;

    try {
      final notificationId = _getNotificationId('pdf_start_$contentId');
      await _notificationsPlugin.show(
        notificationId,
        'Converting to PDF',
        'Converting ${_truncateTitle(title)} to PDF...',
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
            icon: '@drawable/ic_pdf',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        payload: contentId,
      );

      _logger.d('PDF conversion started notification shown for: $contentId');
    } catch (e) {
      _logger.e('Failed to show PDF conversion started notification: $e');
    }
  }

  /// Update PDF conversion progress notification
  /// Updates the progress bar during PDF conversion
  Future<void> updatePdfConversionProgress({
    required String contentId,
    required int progress,
    required String title,
  }) async {
    if (!isEnabled) return;

    try {
      final notificationId = _getNotificationId('pdf_progress_$contentId');
      await _notificationsPlugin.show(
        notificationId,
        'Converting to PDF ($progress%)',
        'Converting ${_truncateTitle(title)} to PDF...',
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
            progress: progress,
            icon: '@drawable/ic_pdf',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        payload: contentId,
      );

      _logger.d('PDF conversion progress updated for $contentId: $progress%');
    } catch (e) {
      _logger.e('Failed to update PDF conversion progress notification: $e');
    }
  }

  /// Show PDF conversion completed notification
  /// Displays success notification when PDF conversion is done
  Future<void> showPdfConversionCompleted({
    required String contentId,
    required String title,
    required List<String> pdfPaths,
    required int partsCount,
  }) async {
    if (!isEnabled) return;

    try {
      final notificationId = _getNotificationId('pdf_complete_$contentId');
      final message = partsCount > 1 
          ? '${_truncateTitle(title)} converted to $partsCount PDF files'
          : '${_truncateTitle(title)} converted to PDF';

      await _notificationsPlugin.show(
        notificationId,
        'PDF Created Successfully',
        message,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _downloadChannelId,
            _downloadChannelName,
            channelDescription: _downloadChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            ongoing: false,
            autoCancel: true,
            showProgress: false,
            icon: '@drawable/ic_pdf',
            actions: [
              AndroidNotificationAction(
                'open_pdf',
                'Open PDF',
                icon: DrawableResourceAndroidBitmap('@drawable/ic_open'),
              ),
              AndroidNotificationAction(
                'share_pdf',
                'Share',
                icon: DrawableResourceAndroidBitmap('@drawable/ic_share'),
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: pdfPaths.isNotEmpty ? pdfPaths.first : contentId,
      );

      _logger.i('PDF conversion completed notification shown for: $contentId');
    } catch (e) {
      _logger.e('Failed to show PDF conversion completed notification: $e');
    }
  }

  /// Show PDF conversion error notification
  /// Displays error notification when PDF conversion fails
  Future<void> showPdfConversionError({
    required String contentId,
    required String title,
    required String error,
  }) async {
    if (!isEnabled) return;

    try {
      final notificationId = _getNotificationId('pdf_error_$contentId');
      await _notificationsPlugin.show(
        notificationId,
        'PDF Conversion Failed',
        'Failed to convert ${_truncateTitle(title)} to PDF: ${_truncateError(error)}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _downloadChannelId,
            _downloadChannelName,
            channelDescription: _downloadChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            ongoing: false,
            autoCancel: true,
            showProgress: false,
            icon: '@drawable/ic_error',
            actions: [
              AndroidNotificationAction(
                'retry_pdf',
                'Retry',
                icon: DrawableResourceAndroidBitmap('@drawable/ic_refresh'),
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: contentId,
      );

      _logger.e('PDF conversion error notification shown for: $contentId - $error');
    } catch (e) {
      _logger.e('Failed to show PDF conversion error notification: $e');
    }
  }

  /// Check if notifications are enabled
  bool get isEnabled => _permissionGranted && _initialized;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request notification permission first
      final permissionStatus = await requestNotificationPermission();
      
      if (!permissionStatus) {
        _logger.w('NotificationService: Permission denied, notifications will be disabled');
        _permissionGranted = false;
        _initialized = false;
        return;
      }
      
      _permissionGranted = true;
      
      // Android initialization
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // Already requested above
        requestBadgePermission: false,
        requestSoundPermission: false,
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

      _initialized = true;
      _logger.i('NotificationService initialized successfully');
    } catch (e) {
      _initialized = false;
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
    if (!isEnabled) {
      _logger.d('NotificationService: Notifications disabled, skipping started notification');
      return;
    }
    
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
    if (!isEnabled) {
      _logger.d('NotificationService: Notifications disabled, skipping progress update');
      return;
    }
    
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
    if (!isEnabled) {
      _logger.d('NotificationService: Notifications disabled, skipping completed notification');
      return;
    }
    
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
    if (!isEnabled) {
      _logger.d('NotificationService: Notifications disabled, skipping error notification');
      return;
    }
    
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
