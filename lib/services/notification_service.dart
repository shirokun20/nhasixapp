import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import 'notifications/notification_action_handler.dart';
import 'notifications/notification_constants.dart';
import 'notifications/notification_details_builder.dart';
import 'notifications/notification_permission_handler.dart';
import 'notifications/notification_id_manager.dart';

/// Service untuk handle local notifications untuk download
///
/// Cara penggunaan dengan DownloadBloc:
/// ```dart
/// final notificationService = NotificationService.withCallbacks(
///   logger: logger,
///   onDownloadPause: (contentId) => downloadBloc.add(DownloadPauseEvent(contentId)),
///   onDownloadResume: (contentId) => downloadBloc.add(DownloadResumeEvent(contentId)),
///   onDownloadCancel: (contentId) => downloadBloc.add(DownloadCancelEvent(contentId)),
///   onDownloadRetry: (contentId) => downloadBloc.add(DownloadRetryEvent(contentId)),
///   onPdfRetry: (contentId) => pdfConversionService.retry(contentId),
///   onOpenDownload: (contentId) => openDownloadedFile(contentId),
///   onNavigateToDownloads: (contentId) => navigateToDownloadsScreen(contentId),
/// );
/// await notificationService.initialize();
/// ```
///
/// Action IDs yang didukung:
/// - `pause`: Pause download
/// - `resume`: Resume download
/// - `cancel`: Cancel download
/// - `retry`: Retry failed download
/// - `open`: Open downloaded content
/// - `open_pdf`: Open PDF file
/// - `share_pdf`: Share PDF file
/// - `retry_pdf`: Retry PDF conversion
/// - `null` (default): Navigate to downloads screen atau open PDF
class NotificationService {
  NotificationService({
    Logger? logger,
    this.onDownloadPause,
    this.onDownloadResume,
    this.onDownloadCancel,
    this.onDownloadRetry,
    this.onPdfRetry,
    this.onOpenDownload,
    this.onNavigateToDownloads,
  }) : _logger = logger ?? Logger() {
    // Initialize action handler with callbacks
    _actionHandler = NotificationActionHandler(
      logger: _logger,
      onDownloadPause: onDownloadPause,
      onDownloadResume: onDownloadResume,
      onDownloadCancel: onDownloadCancel,
      onDownloadRetry: onDownloadRetry,
      onPdfRetry: onPdfRetry,
      onOpenDownload: onOpenDownload,
      onNavigateToDownloads: onNavigateToDownloads,
    );

    // Initialize permission handler and ID manager
    _permissionHandler = NotificationPermissionHandler(logger: _logger);
    _idManager = NotificationIdManager();
  }

  final Logger _logger;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Callback functions for handling notification actions
  void Function(String contentId)? onDownloadPause;
  void Function(String contentId)? onDownloadResume;
  void Function(String contentId)? onDownloadCancel;
  void Function(String contentId)? onDownloadRetry;
  void Function(String contentId)? onPdfRetry;
  void Function(String contentId)? onOpenDownload;
  void Function(String? contentId)? onNavigateToDownloads;

  // Localization callback
  String Function(String key, {Map<String, dynamic>? args})? _localize;

  bool _permissionGranted = false;
  bool _initialized = false;

  // Action handler for notification actions
  late final NotificationActionHandler _actionHandler;
  late final NotificationPermissionHandler _permissionHandler;
  late final NotificationIdManager _idManager;

  // Channel IDs imported from NotificationChannels in notification_constants.dart

  /// Request notification permission from user
  /// Enhanced for Android 13+ and release mode compatibility
  /// Request notification permission from user
  Future<bool> requestNotificationPermission() async {
    return _permissionHandler.requestPermission();
  }

  /// Show PDF conversion started notification
  /// Displays a notification when PDF conversion begins
  Future<void> showPdfConversionStarted({
    required String contentId,
    required String title,
  }) async {
    debugPrint(
        'PDF_NOTIFICATION: showPdfConversionStarted - ENTER method for contentId=$contentId, title=$title');

    _logger.i(
        'NotificationService: showPdfConversionStarted called for $contentId (title: $title)');
    _logger.i(
        'NotificationService: isEnabled = $isEnabled (_permissionGranted: $_permissionGranted, _initialized: $_initialized)');

    debugPrint(
        'PDF_NOTIFICATION: showPdfConversionStarted - isEnabled=$isEnabled, _permissionGranted=$_permissionGranted, _initialized=$_initialized');

    if (!isEnabled) {
      _logger.w(
          'NotificationService: PDF conversion start notification disabled, skipping for $contentId');
      debugPrint(
          'PDF_NOTIFICATION: showPdfConversionStarted - DISABLED, returning early');
      return;
    }

    try {
      debugPrint(
          'PDF_NOTIFICATION: showPdfConversionStarted - Starting notification creation');

      _logger.i(
          'NotificationService: Showing PDF conversion started notification for $contentId');
      final notificationId = _getNotificationId('pdf_$contentId');

      debugPrint(
          'PDF_NOTIFICATION: showPdfConversionStarted - Generated notificationId=$notificationId');
      debugPrint(
          'PDF_NOTIFICATION: showPdfConversionStarted - Using channel: ${NotificationChannels.downloadChannelId}');
      debugPrint(
          'PDF_NOTIFICATION: showPdfConversionStarted - About to call _notificationsPlugin.show()');

      await _notificationsPlugin.show(
        notificationId,
        _getLocalized('convertingToPdf', fallback: 'Converting to PDF'),
        _getLocalized('convertingToPdfWithTitle',
            args: {'title': _truncateTitle(title)},
            fallback: 'Converting ${_truncateTitle(title)} to PDF...'),
        NotificationDetailsBuilder.progress(progress: 0),
        payload: contentId,
      );

      debugPrint(
          'PDF_NOTIFICATION: showPdfConversionStarted - _notificationsPlugin.show() completed successfully');
      _logger.i(
          'PDF conversion started notification shown successfully for: $contentId');
    } catch (e, stackTrace) {
      debugPrint(
          'PDF_NOTIFICATION: showPdfConversionStarted - EXCEPTION caught: ${e.toString()}');
      debugPrint(
          'PDF_NOTIFICATION: showPdfConversionStarted - STACKTRACE: ${stackTrace.toString()}');
      _logger.e(
          'Failed to show PDF conversion started notification for $contentId: $e',
          error: e,
          stackTrace: stackTrace);
    }

    debugPrint('PDF_NOTIFICATION: showPdfConversionStarted - EXIT method');
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
      final notificationId = _getNotificationId('pdf_$contentId');
      await _notificationsPlugin.show(
        notificationId,
        _getLocalized('convertingToPdfProgress',
            args: {'progress': progress},
            fallback: 'Converting to PDF ($progress%)'),
        _getLocalized('convertingToPdfProgressWithTitle',
            args: {'title': _truncateTitle(title), 'progress': progress},
            fallback: 'Converting ${_truncateTitle(title)} to PDF...'),
        NotificationDetailsBuilder.progress(progress: progress),
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
    _logger.i(
        'NotificationService: showPdfConversionCompleted called for $contentId (title: $title, parts: $partsCount)');
    _logger.i(
        'NotificationService: isEnabled = $isEnabled (_permissionGranted: $_permissionGranted, _initialized: $_initialized)');

    if (!isEnabled) {
      _logger.w(
          'NotificationService: PDF conversion completed notification disabled, skipping for $contentId');
      return;
    }

    try {
      _logger.i(
          'NotificationService: Showing PDF conversion completed notification for $contentId');
      final notificationId = _getNotificationId('pdf_$contentId');
      final message = partsCount > 1
          ? _getLocalized('pdfCreatedWithParts',
              args: {'title': _truncateTitle(title), 'partsCount': partsCount},
              fallback:
                  '${_truncateTitle(title)} converted to $partsCount PDF files')
          : _getLocalized('convertingToPdfWithTitle',
              args: {'title': _truncateTitle(title)},
              fallback: '${_truncateTitle(title)} converted to PDF');

      await _notificationsPlugin.show(
        notificationId,
        _getLocalized('pdfCreatedSuccessfully',
            fallback: 'PDF Created Successfully'),
        message,
        NotificationDetailsBuilder.success(
          bigText: message,
          contentTitle: 'PDF Created Successfully',
          summaryText: 'Tap to open PDF',
          actions: NotificationDetailsBuilder.pdfCompletedActions(),
        ),
        payload: pdfPaths.isNotEmpty ? pdfPaths.first : contentId,
      );

      _logger.i('PDF conversion completed notification shown for: $contentId');
      _logger.i(
          '📋 Notification created with actions: [open_pdf, share_pdf] for PDF: ${pdfPaths.isNotEmpty ? pdfPaths.first : "unknown"}');

      // Log the exact actions we're creating for debugging
      _logger
          .i('🔧 Action 1: open_pdf - "Open PDF" with icon @drawable/ic_open');
      _logger
          .i('🔧 Action 2: share_pdf - "Share" with icon @drawable/ic_share');
      _logger.i('🔧 Notification ID: ${contentId.hashCode}');
      _logger.i('🔧 Channel: download_channel (Importance.high)');
      _logger.i('🔧 Style: BigTextStyleInformation with summaryText');
      _logger.i('🔧 showsUserInterface: true for both actions');
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
    _logger.i(
        'NotificationService: showPdfConversionError called for $contentId (title: $title, error: $error)');
    _logger.i(
        'NotificationService: isEnabled = $isEnabled (_permissionGranted: $_permissionGranted, _initialized: $_initialized)');

    if (!isEnabled) {
      _logger.w(
          'NotificationService: PDF conversion error notification disabled, skipping for $contentId');
      return;
    }

    try {
      _logger.i(
          'NotificationService: Showing PDF conversion error notification for $contentId');
      final notificationId = _getNotificationId('pdf_$contentId');
      await _notificationsPlugin.show(
        notificationId,
        _getLocalized('pdfConversionFailed', fallback: 'PDF Conversion Failed'),
        _getLocalized('pdfConversionFailedWithError',
            args: {
              'title': _truncateTitle(title),
              'error': _truncateError(error)
            },
            fallback:
                'Failed to convert ${_truncateTitle(title)} to PDF: ${_truncateError(error)}'),
        NotificationDetailsBuilder.error(
          actions: NotificationDetailsBuilder.pdfErrorActions(),
        ),
        payload: contentId,
      );

      _logger.e(
          'PDF conversion error notification shown for: $contentId - $error');
    } catch (e) {
      _logger.e('Failed to show PDF conversion error notification: $e');
    }
  }

  /// Check if notifications are enabled
  bool get isEnabled => _permissionGranted && _initialized;

  /// Debug method to log current notification service state
  void debugLogState([String? context]) {
    final contextStr = context != null ? ' ($context)' : '';
    _logger.i('NotificationService State$contextStr:');
    _logger.i('  - _permissionGranted: $_permissionGranted');
    _logger.i('  - _initialized: $_initialized');
    _logger.i('  - isEnabled: $isEnabled');
    _logger.i('  - Platform: ${Platform.operatingSystem}');
  }

  /// Initialize notification service
  /// Enhanced initialization for debug and release mode compatibility
  Future<void> initialize() async {
    try {
      _logger.i('NotificationService: Starting initialization...');

      // Request notification permission first
      final permissionStatus = await requestNotificationPermission();

      if (!permissionStatus) {
        _logger.w(
            'NotificationService: Permission denied, notifications will be disabled');
        _permissionGranted = false;
        _initialized = false;
        return;
      }

      _permissionGranted = true;
      _logger.i(
          'NotificationService: Permission granted, proceeding with initialization');

      // Android initialization
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization - request permissions during init for iOS
      final DarwinInitializationSettings iosSettings;
      if (Platform.isIOS) {
        iosSettings = const DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
      } else {
        iosSettings = const DarwinInitializationSettings(
          requestAlertPermission: false, // Already requested above for non-iOS
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
      }

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initResult = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initResult == null || !initResult) {
        _logger.w(
            'NotificationService: Plugin initialization returned false or null');
      } else {
        _logger.i('NotificationService: Plugin initialization successful');
      }

      // Create notification channel for Android
      await _createNotificationChannel();

      _initialized = true;
      _logger.i(
          'NotificationService initialized successfully (Permission: $_permissionGranted, Initialized: $_initialized)');
    } catch (e, stackTrace) {
      _initialized = false;
      _permissionGranted = false;
      _logger.e('Failed to initialize NotificationService: $e',
          error: e, stackTrace: stackTrace);

      // Try a simplified initialization as fallback
      try {
        _logger.i('NotificationService: Attempting fallback initialization...');
        const simpleSettings = InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        );

        await _notificationsPlugin.initialize(simpleSettings);
        _initialized = true;
        _permissionGranted = true; // Assume granted for fallback
        _logger.w('NotificationService: Fallback initialization completed');
      } catch (fallbackError) {
        _logger.e(
            'NotificationService: Fallback initialization also failed: $fallbackError');
        _initialized = false;
        _permissionGranted = false;
      }
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      NotificationChannels.downloadChannelId,
      NotificationChannels.downloadChannelName,
      description: NotificationChannels.downloadChannelDescription,
      importance: Importance.high, // High importance for action buttons to work
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Delegate to action handler
    _actionHandler.handleAction(
      actionId: response.actionId,
      payload: response.payload,
      onCancelNotification: cancelDownloadNotification,
    );
  }

  /// Show download started notification
  Future<void> showDownloadStarted({
    required String contentId,
    required String title,
  }) async {
    if (!isEnabled) {
      _logger.d(
          'NotificationService: Notifications disabled, skipping started notification');
      return;
    }

    try {
      final notificationId = _getNotificationId(contentId);

      await _notificationsPlugin.show(
        notificationId,
        _getLocalized('downloadStarted', fallback: 'Download Started'),
        _getLocalized('downloadingWithTitle',
            args: {'title': _truncateTitle(title)},
            fallback: 'Downloading: ${_truncateTitle(title)}'),
        NotificationDetailsBuilder.progress(progress: 0),
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
      _logger.d(
          'NotificationService: Notifications disabled, skipping progress update');
      return;
    }

    try {
      final notificationId = _getNotificationId(contentId);
      final statusText = isPaused
          ? _getLocalized('downloadPaused', fallback: 'Paused')
          : _getLocalized('downloadingProgress',
              args: {'progress': progress},
              fallback: 'Downloading ($progress%)');

      await _notificationsPlugin.show(
        notificationId,
        statusText,
        _truncateTitle(title),
        NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationChannels.downloadChannelId,
            NotificationChannels.downloadChannelName,
            channelDescription: NotificationChannels.downloadChannelDescription,
            importance: Importance.low,
            priority: Priority.low,
            ongoing: !isPaused,
            autoCancel: false,
            showProgress: true,
            playSound: false,
            maxProgress: 100,
            progress: progress,
            actions: isPaused
                ? [
                    // Show resume action when paused
                    AndroidNotificationAction(
                      'resume',
                      'Resume',
                      showsUserInterface: true,
                    ),
                    AndroidNotificationAction(
                      'cancel',
                      'Cancel',
                      showsUserInterface: true,
                    ),
                  ]
                : [
                    // Show pause action when downloading
                    AndroidNotificationAction(
                      'pause',
                      'Pause',
                      showsUserInterface: true,
                    ),
                    AndroidNotificationAction(
                      'cancel',
                      'Cancel',
                      showsUserInterface: true,
                    ),
                  ],
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
      _logger.d(
          'NotificationService: Notifications disabled, skipping completed notification');
      return;
    }

    try {
      final notificationId = _getNotificationId(contentId);

      await _notificationsPlugin.show(
        notificationId,
        _getLocalized('downloadComplete', fallback: 'Download Complete'),
        _getLocalized('downloadedWithTitle',
            args: {'title': _truncateTitle(title)},
            fallback: 'Downloaded: ${_truncateTitle(title)}'),
        NotificationDetailsBuilder.success(
          actions: NotificationDetailsBuilder.downloadCompletedActions(),
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
      _logger.d(
          'NotificationService: Notifications disabled, skipping error notification');
      return;
    }

    try {
      final notificationId = _getNotificationId(contentId);

      await _notificationsPlugin.show(
        notificationId,
        _getLocalized('downloadFailed', fallback: 'Download Failed'),
        _getLocalized('downloadFailedWithTitle',
            args: {'title': _truncateTitle(title)},
            fallback: 'Failed: ${_truncateTitle(title)}'),
        NotificationDetailsBuilder.error(
          bigText: 'Download failed: ${_truncateError(error)}',
          contentTitle: 'Download Failed',
          summaryText: _truncateTitle(title),
          actions: NotificationDetailsBuilder.downloadErrorActions(),
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
  /// Get notification ID from content ID
  int _getNotificationId(String contentId) {
    return _idManager.getNotificationId(contentId);
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

  /// Test action buttons functionality
  Future<void> showTestActionNotification() async {
    if (!isEnabled) return;

    try {
      await _notificationsPlugin.show(
        99999, // Fixed test ID
        'Test Action Buttons',
        'This is a test notification with action buttons',
        NotificationDetails(
          android: AndroidNotificationDetails(
            NotificationChannels.downloadChannelId,
            NotificationChannels.downloadChannelName,
            channelDescription: NotificationChannels.downloadChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            ongoing: false,
            autoCancel: true,
            // Remove icons and actions to avoid drawable resource errors
            styleInformation: const BigTextStyleInformation(
              'Simple test notification without icons',
              contentTitle: 'Test Action Buttons',
              summaryText: 'Testing...',
            ),
          ),
        ),
        payload: '/test/path/test.pdf',
      );

      _logger.i('🧪 Test action notification created');
    } catch (e) {
      _logger.e('Failed to show test action notification: $e');
    }
  }

  /// Quick test method to be called from main for debugging
  static Future<void> testNotificationActions() async {
    final service = NotificationService();
    await service.initialize();
    await service.showTestActionNotification();
  }

  /// Factory constructor untuk setup NotificationService dengan DownloadBloc
  /// Ini memudahkan integrasi dengan DownloadBloc tanpa tight coupling
  static NotificationService withCallbacks({
    required Logger logger,
    required void Function(String contentId) onDownloadPause,
    required void Function(String contentId) onDownloadResume,
    required void Function(String contentId) onDownloadCancel,
    required void Function(String contentId) onDownloadRetry,
    required void Function(String contentId) onPdfRetry,
    required void Function(String contentId) onOpenDownload,
    required void Function(String? contentId) onNavigateToDownloads,
  }) {
    return NotificationService(
      logger: logger,
      onDownloadPause: onDownloadPause,
      onDownloadResume: onDownloadResume,
      onDownloadCancel: onDownloadCancel,
      onDownloadRetry: onDownloadRetry,
      onPdfRetry: onPdfRetry,
      onOpenDownload: onOpenDownload,
      onNavigateToDownloads: onNavigateToDownloads,
    );
  }

  /// Set callbacks after initialization (for dependency injection scenarios)
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

    // Also update action handler callbacks
    _actionHandler.setCallbacks(
      onDownloadPause: onDownloadPause,
      onDownloadResume: onDownloadResume,
      onDownloadCancel: onDownloadCancel,
      onDownloadRetry: onDownloadRetry,
      onPdfRetry: onPdfRetry,
      onOpenDownload: onOpenDownload,
      onNavigateToDownloads: onNavigateToDownloads,
    );

    _logger.i('NotificationService: Callbacks updated');
  }

  /// Set localization callback for getting localized strings
  void setLocalizationCallback(
      String Function(String key, {Map<String, dynamic>? args}) localize) {
    _localize = localize;
    _logger.i('NotificationService: Localization callback set');
  }

  /// Get localized string with fallback
  String _getLocalized(String key,
      {Map<String, dynamic>? args, String? fallback}) {
    try {
      return _localize?.call(key, args: args) ?? fallback ?? key;
    } catch (e) {
      _logger.w('Failed to get localized string for key: $key, error: $e');
      return fallback ?? key;
    }
  }

  // ============================================================
  // SYNC NOTIFICATIONS
  // ============================================================

  /// Fixed notification ID for sync operations
  static const int _syncNotificationId = 888888;

  /// Show sync started notification
  Future<void> showSyncStarted({String? message}) async {
    if (!isEnabled) return;

    try {
      await _notificationsPlugin.show(
        _syncNotificationId,
        _getLocalized('syncInProgress', fallback: 'Syncing Data'),
        message ??
            _getLocalized('syncingOfflineContent',
                fallback: 'Loading offline content...'),
        NotificationDetailsBuilder.progress(progress: 0),
        payload: 'sync',
      );

      _logger.d('Sync started notification shown');
    } catch (e) {
      _logger.e('Failed to show sync started notification: $e');
    }
  }

  /// Update sync progress notification
  Future<void> updateSyncProgress({
    required int progress,
    required String message,
  }) async {
    if (!isEnabled) return;

    try {
      await _notificationsPlugin.show(
        _syncNotificationId,
        _getLocalized('syncingProgress',
            args: {'progress': progress}, fallback: 'Syncing ($progress%)'),
        message,
        NotificationDetailsBuilder.progress(progress: progress),
        payload: 'sync',
      );

      _logger.d('Sync progress updated: $progress%');
    } catch (e) {
      _logger.e('Failed to update sync progress notification: $e');
    }
  }

  /// Show sync completed notification
  Future<void> showSyncCompleted({required int itemCount}) async {
    if (!isEnabled) return;

    try {
      await _notificationsPlugin.show(
        _syncNotificationId,
        _getLocalized('syncComplete', fallback: 'Sync Complete'),
        _getLocalized('syncCompletedWithCount',
            args: {'count': itemCount},
            fallback: 'Found $itemCount offline content'),
        NotificationDetailsBuilder.success(),
        payload: 'sync',
      );

      _logger.i('Sync completed notification shown: $itemCount items');

      // Auto-dismiss after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        cancelSyncNotification();
      });
    } catch (e) {
      _logger.e('Failed to show sync completed notification: $e');
    }
  }

  /// Cancel sync notification
  Future<void> cancelSyncNotification() async {
    try {
      await _notificationsPlugin.cancel(_syncNotificationId);
      _logger.d('Sync notification cancelled');
    } catch (e) {
      _logger.e('Failed to cancel sync notification: $e');
    }
  }
}
