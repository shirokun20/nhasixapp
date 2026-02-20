import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String tagName;
  final String content; // Changelog
  final String downloadUrl;

  UpdateInfo({
    required this.tagName,
    required this.content,
    required this.downloadUrl,
  });
}

class UpdateService {
  final Dio _dio;
  final Logger _logger;

  // New API details
  static const String _baseUrl = 'https://ktapk.org';
  static const String _checkUpdateEndpoint = '/api/check-update';

  UpdateService({
    required Logger logger,
  })  : _logger = logger,
        _dio = Dio();

  /// Checks for update and returns [UpdateInfo] if a newer version is available.
  /// Returns null if up to date or error.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      _logger.i('UpdateService: Checking for updates from $_baseUrl...');

      // Get current app version info
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode =
          packageInfo.buildNumber; // e.g., 1 (integer as string)
      final currentVersionName = packageInfo.version;

      _logger.d(
          'UpdateService: Current version: $currentVersionName ($currentVersionCode)');

      // Call API with version_code
      final response = await _dio.get(
        '$_baseUrl$_checkUpdateEndpoint',
        queryParameters: {'version_code': currentVersionCode},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Validate response status
        if (data['status'] != 'success') {
          _logger.w('UpdateService: API returned status ${data['status']}');
          return null;
        }

        final updateData = data['data'];
        final bool updateAvailable = updateData['update_available'] ?? false;

        if (updateAvailable) {
          final latestVersion = updateData['latest_version'];
          final String versionCode = latestVersion['code']?.toString() ?? '';
          final String versionName = latestVersion['name'] ?? '';
          final String changelog =
              latestVersion['changelog'] ?? 'No changelog available.';
          // Handle relative URL (preserved for potential future use or logging)
          // String downloadUrl = downloadPath;
          // if (downloadPath.isNotEmpty && !downloadPath.startsWith('http')) {
          //    downloadUrl = '$_baseUrl$downloadPath';
          // }

          // User requested to always redirect to the general download page
          const String downloadUrl = 'https://ktapk.org/download';

          _logger.i(
              'UpdateService: New version found: $versionName ($versionCode)');
          return UpdateInfo(
            tagName:
                versionName, // Using version name as tagName for UI compatibility
            content: changelog,
            downloadUrl: downloadUrl,
          );
        } else {
          _logger.d('UpdateService: App is up to date.');
          return null;
        }
      } else {
        _logger.w('UpdateService: API returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('UpdateService: Error checking update', error: e);
      return null;
    }
  }

  // _isNewerVersion is likely no longer needed as the API decides 'update_available',
  // but keeping it or removing it depends on if we want client-side double-check.
  // The API response explicitly says "update_available": true/false, so we rely on that.
}
