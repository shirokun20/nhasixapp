import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

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
      final notificationId = _getNotificationId('pdf_$contentId');
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
      final notificationId = _getNotificationId('pdf_$contentId');
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
      final notificationId = _getNotificationId('pdf_$contentId');
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
            largeIcon: DrawableResourceAndroidBitmap('@drawable/ic_pdf'),
            styleInformation: BigTextStyleInformation(
              message,
              contentTitle: 'PDF Created Successfully',
              summaryText: 'Tap to open or use buttons below',
            ),
            actions: [
              AndroidNotificationAction(
                'open_pdf',
                'Open PDF',
                icon: DrawableResourceAndroidBitmap('@drawable/ic_open'),
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'share_pdf',
                'Share',
                icon: DrawableResourceAndroidBitmap('@drawable/ic_share'),
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
        payload: pdfPaths.isNotEmpty ? pdfPaths.first : contentId,
      );

      _logger.i('PDF conversion completed notification shown for: $contentId');
      _logger.i('📋 Notification created with actions: [open_pdf, share_pdf] for PDF: ${pdfPaths.isNotEmpty ? pdfPaths.first : "unknown"}');
      
      // Log the exact actions we're creating for debugging
      _logger.i('🔧 Action 1: open_pdf - "Open PDF" with icon @drawable/ic_open');
      _logger.i('🔧 Action 2: share_pdf - "Share" with icon @drawable/ic_share');
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
    if (!isEnabled) return;

    try {
      final notificationId = _getNotificationId('pdf_$contentId');
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
    _logger.i('🔔 Notification tapped! ActionId: "${response.actionId}", Payload: "${response.payload}"');

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
      case 'open_pdf':
        _logger.i('📂 Open PDF action tapped for: ${response.payload}');
        _openPdfFile(response.payload);
        break;
      case 'share_pdf':
        _logger.i('📤 Share PDF action tapped for: ${response.payload}');
        _sharePdfFile(response.payload);
        break;
      case 'retry_pdf':
        _logger.d('Retry PDF action tapped for: ${response.payload}');
        // TODO: Implement retry PDF conversion
        break;
      case null:
        _logger.i('📱 Default notification body tapped for: ${response.payload}');
        // Check if payload is a PDF file path and open it
        if (response.payload != null && response.payload!.endsWith('.pdf')) {
          _logger.i('📂 Opening PDF from default tap: ${response.payload}');
          _openPdfFile(response.payload);
        } else {
          // TODO: Navigate to downloads screen
          _logger.d('Navigate to downloads screen for: ${response.payload}');
        }
        break;
      default:
        _logger.w('⚠️ Unknown action tapped: "${response.actionId}" for: ${response.payload}');
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
            icon: '@drawable/ic_pdf',
            styleInformation: const BigTextStyleInformation(
              'Tap the action buttons below to test functionality',
              contentTitle: 'Test Action Buttons',
              summaryText: 'Testing...',
            ),
            actions: [
              AndroidNotificationAction(
                'open_pdf',
                'Test Open',
                icon: DrawableResourceAndroidBitmap('@drawable/ic_open'),
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'share_pdf',
                'Test Share',
                icon: DrawableResourceAndroidBitmap('@drawable/ic_share'),
                showsUserInterface: true,
              ),
            ],
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
}
