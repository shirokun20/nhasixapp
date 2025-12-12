import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
  }) : _logger = logger ?? Logger();

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

  // Notification channels
  static const String _downloadChannelId = 'download_channel';
  static const String _downloadChannelName = 'Downloads';
  static const String _downloadChannelDescription =
      'Download progress notifications';

  /// Request notification permission from user
  /// Enhanced for Android 13+ and release mode compatibility
  Future<bool> requestNotificationPermission() async {
    try {
      // For Android, handle version-specific permission logic
      if (Platform.isAndroid) {
        // Get Android version info for API level checking
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        _logger.i('NotificationService: Android SDK: $sdkInt');

        if (sdkInt >= 33) {
          // Android 13+ (API 33+) requires explicit notification permission
          _logger.i(
              'NotificationService: Requesting notification permission for Android 13+');
          final status = await Permission.notification.request();

          if (status.isGranted) {
            _logger.i('NotificationService: Permission granted (Android 13+)');
            return true;
          } else if (status.isDenied) {
            _logger.w('NotificationService: Permission denied (Android 13+)');
            return false;
          } else if (status.isPermanentlyDenied) {
            _logger.w(
                'NotificationService: Permission permanently denied (Android 13+)');
            return false;
          } else if (status.isRestricted) {
            _logger
                .w('NotificationService: Permission restricted (Android 13+)');
            return false;
          }

          _logger.w('NotificationService: Unknown permission status: $status');
          return false;
        } else {
          // Android 12 and below - notifications enabled by default
          _logger.i(
              'NotificationService: Android 12 and below - notifications enabled by default');
          return true;
        }
      } else if (Platform.isIOS) {
        // iOS permission handling
        _logger.i(
            'NotificationService: Requesting notification permission for iOS');
        final status = await Permission.notification.request();

        if (status.isGranted) {
          _logger.i('NotificationService: Permission granted (iOS)');
          return true;
        } else {
          _logger.w('NotificationService: Permission denied (iOS)');
          return false;
        }
      }

      // Fallback for other platforms
      _logger.w(
          'NotificationService: Unknown platform, assuming permission granted');
      return true;
    } catch (e, stackTrace) {
      _logger.e('NotificationService: Error requesting permission: $e',
          error: e, stackTrace: stackTrace);

      // In case of error, try fallback approach
      try {
        final status = await Permission.notification.request();
        final granted = status.isGranted;
        _logger.w('NotificationService: Fallback permission result: $granted');
        return granted;
      } catch (fallbackError) {
        _logger.e(
            'NotificationService: Fallback permission also failed: $fallbackError');
        return false;
      }
    }
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
          'PDF_NOTIFICATION: showPdfConversionStarted - Using channel: $_downloadChannelId');
      debugPrint(
          'PDF_NOTIFICATION: showPdfConversionStarted - About to call _notificationsPlugin.show()');

      await _notificationsPlugin.show(
        notificationId,
        _getLocalized('convertingToPdf', fallback: 'Converting to PDF'),
        _getLocalized('convertingToPdfWithTitle',
            args: {'title': _truncateTitle(title)},
            fallback: 'Converting ${_truncateTitle(title)} to PDF...'),
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
            // Remove icon to avoid drawable resource errors (same as download notifications)
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
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
            playSound: false,
            maxProgress: 100,
            progress: progress,
            // Remove icon to avoid drawable resource errors
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
            // Add actions without custom icons (same pattern as download notification)
            actions: [
              AndroidNotificationAction(
                'open_pdf',
                'Open PDF',
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'share_pdf',
                'Share',
                showsUserInterface: true,
              ),
            ],
            styleInformation: BigTextStyleInformation(
              message,
              contentTitle: 'PDF Created Successfully',
              summaryText: 'Tap to open PDF',
            ),
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
            // Add retry action without custom icon
            actions: [
              AndroidNotificationAction(
                'retry_pdf',
                'Retry',
                showsUserInterface: true,
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
      _downloadChannelId,
      _downloadChannelName,
      description: _downloadChannelDescription,
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
    _logger.i(
        '🔔 Notification tapped! ActionId: "${response.actionId}", Payload: "${response.payload}"');

    // Handle different notification actions
    switch (response.actionId) {
      case 'pause':
        _logger.i('⏸️ Pause action tapped for: ${response.payload}');
        if (response.payload != null && onDownloadPause != null) {
          try {
            onDownloadPause!(response.payload!);
            _logger.i('✅ Download pause triggered for: ${response.payload}');
          } catch (e) {
            _logger.e('❌ Error pausing download: $e');
          }
        } else {
          _logger.w('⚠️ Cannot pause: payload is null or callback not set');
        }
        break;

      case 'resume':
        _logger.i('▶️ Resume action tapped for: ${response.payload}');
        if (response.payload != null && onDownloadResume != null) {
          try {
            onDownloadResume!(response.payload!);
            _logger.i('✅ Download resume triggered for: ${response.payload}');
          } catch (e) {
            _logger.e('❌ Error resuming download: $e');
          }
        } else {
          _logger.w('⚠️ Cannot resume: payload is null or callback not set');
        }
        break;

      case 'cancel':
        _logger.i('❌ Cancel action tapped for: ${response.payload}');
        if (response.payload != null && onDownloadCancel != null) {
          try {
            onDownloadCancel!(response.payload!);
            _logger.i('✅ Download cancel triggered for: ${response.payload}');
            // Also cancel the notification
            cancelDownloadNotification(response.payload!);
          } catch (e) {
            _logger.e('❌ Error cancelling download: $e');
          }
        } else {
          _logger.w('⚠️ Cannot cancel: payload is null or callback not set');
        }
        break;

      case 'retry':
        _logger.i('🔄 Retry download action tapped for: ${response.payload}');
        if (response.payload != null && onDownloadRetry != null) {
          try {
            onDownloadRetry!(response.payload!);
            _logger.i('✅ Download retry triggered for: ${response.payload}');
          } catch (e) {
            _logger.e('❌ Error retrying download: $e');
          }
        } else {
          _logger.w('⚠️ Cannot retry: payload is null or callback not set');
        }
        break;

      case 'open':
        _logger.i(
            '📂 Open downloaded content action tapped for: ${response.payload}');
        if (response.payload != null && onOpenDownload != null) {
          try {
            onOpenDownload!(response.payload!);
            _logger.i('✅ Open download triggered for: ${response.payload}');
          } catch (e) {
            _logger.e('❌ Error opening download: $e');
          }
        } else {
          _logger.w('⚠️ Cannot open: payload is null or callback not set');
        }
        break;

      case 'open_pdf':
        _logger.i('📂 Open PDF action tapped for: ${response.payload}');
        _openPdfFile(response.payload);
        break;

      case 'share_pdf':
        _logger.i('📤 Share PDF action tapped for: ${response.payload}');
        _sharePdfFile(response.payload);
        break;

      case 'retry_pdf':
        _logger.i(
            '🔄 Retry PDF conversion action tapped for: ${response.payload}');
        if (response.payload != null && onPdfRetry != null) {
          try {
            onPdfRetry!(response.payload!);
            _logger.i('✅ PDF retry triggered for: ${response.payload}');
          } catch (e) {
            _logger.e('❌ Error retrying PDF conversion: $e');
          }
        } else {
          _logger.w('⚠️ Cannot retry PDF: payload is null or callback not set');
        }
        break;

      case null:
        _logger
            .i('📱 Default notification body tapped for: ${response.payload}');
        // Check if payload is a PDF file path and open it
        if (response.payload != null && response.payload!.endsWith('.pdf')) {
          _logger.i('📂 Opening PDF from default tap: ${response.payload}');
          _openPdfFile(response.payload);
        } else {
          // Navigate to downloads screen
          _logger
              .i('📱 Navigating to downloads screen for: ${response.payload}');
          if (onNavigateToDownloads != null) {
            try {
              onNavigateToDownloads!(response.payload);
              _logger.i('✅ Navigation to downloads screen triggered');
            } catch (e) {
              _logger.e('❌ Error navigating to downloads screen: $e');
            }
          } else {
            _logger.w('⚠️ Cannot navigate: callback not set');
          }
        }
        break;

      default:
        _logger.w(
            '⚠️ Unknown action tapped: "${response.actionId}" for: ${response.payload}');
        break;
    }
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
      await Share.shareXFiles(
        [xFile],
        text: 'Sharing PDF document',
        subject: 'PDF Document',
      );

      _logger.i('✅ PDF shared successfully: $filePath');
    } catch (e) {
      _logger.e('💥 Exception sharing PDF file: $e');
    }
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
            _downloadChannelId,
            _downloadChannelName,
            channelDescription: _downloadChannelDescription,
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
        NotificationDetails(
          android: AndroidNotificationDetails(
            _downloadChannelId,
            _downloadChannelName,
            channelDescription: _downloadChannelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            ongoing: false,
            autoCancel: true,
            actions: [
              AndroidNotificationAction(
                'open',
                'Open',
                showsUserInterface: true,
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
            actions: [
              AndroidNotificationAction(
                'retry',
                'Retry',
                showsUserInterface: true,
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
            _downloadChannelId,
            _downloadChannelName,
            channelDescription: _downloadChannelDescription,
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
}
