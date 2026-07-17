import 'dart:io';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Handler for notification permissions
class NotificationPermissionHandler {
  final Logger _logger;

  NotificationPermissionHandler({Logger? logger})
      : _logger = logger ?? Logger();

  /// Check if notification permission is already granted without requesting
  Future<bool> checkPermission() async {
    try {
      // For Android, handle version-specific permission logic
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          // Android 13+ requires explicit notification permission
          final status = await Permission.notification.status;
          return status.isGranted;
        } else {
          // Android 12 and below - notifications enabled by default
          return true;
        }
      } else if (Platform.isIOS) {
        // iOS permission handling
        final status = await Permission.notification.status;
        return status.isGranted;
      }

      // Fallback for other platforms
      return true;
    } catch (e, stackTrace) {
      _logger.e('NotificationPermissionHandler: Error checking permission: $e',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Request notification permission from user
  /// Enhanced for Android 13+ and release mode compatibility
  Future<bool> requestPermission() async {
    try {
      // For Android, handle version-specific permission logic
      if (Platform.isAndroid) {
        // Get Android version info for API level checking
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        _logger.i('NotificationPermissionHandler: Android SDK: $sdkInt');

        if (sdkInt >= 33) {
          // Android 13+ (API 33+) requires explicit notification permission
          _logger.i(
              'NotificationPermissionHandler: Requesting notification permission for Android 13+');
          final status = await Permission.notification.request();

          if (status.isGranted) {
            _logger.i(
                'NotificationPermissionHandler: Permission granted (Android 13+)');
            return true;
          } else if (status.isDenied) {
            _logger.w(
                'NotificationPermissionHandler: Permission denied (Android 13+)');
            return false;
          } else if (status.isPermanentlyDenied) {
            _logger.w(
                'NotificationPermissionHandler: Permission permanently denied (Android 13+)');
            return false;
          } else if (status.isRestricted) {
            _logger.w(
                'NotificationPermissionHandler: Permission restricted (Android 13+)');
            return false;
          }

          _logger.w(
              'NotificationPermissionHandler: Unknown permission status: $status');
          return false;
        } else {
          // Android 12 and below - notifications enabled by default
          _logger.i(
              'NotificationPermissionHandler: Android 12 and below - notifications enabled by default');
          return true;
        }
      } else if (Platform.isIOS) {
        // iOS permission handling
        _logger.i(
            'NotificationPermissionHandler: Requesting notification permission for iOS');
        final status = await Permission.notification.request();

        if (status.isGranted) {
          _logger.i('NotificationPermissionHandler: Permission granted (iOS)');
          return true;
        } else {
          _logger.w('NotificationPermissionHandler: Permission denied (iOS)');
          return false;
        }
      }

      // Fallback for other platforms
      _logger.w(
          'NotificationPermissionHandler: Unknown platform, assuming permission granted');
      return true;
    } catch (e, stackTrace) {
      _logger.e(
          'NotificationPermissionHandler: Error requesting permission: $e',
          error: e,
          stackTrace: stackTrace);

      // In case of error, try fallback approach
      try {
        final status = await Permission.notification.request();
        final granted = status.isGranted;
        _logger.w(
            'NotificationPermissionHandler: Fallback permission result: $granted');
        return granted;
      } catch (fallbackError) {
        _logger.e(
            'NotificationPermissionHandler: Fallback permission also failed: $fallbackError');
        return false;
      }
    }
  }
}
