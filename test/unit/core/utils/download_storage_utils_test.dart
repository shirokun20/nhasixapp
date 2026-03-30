import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/utils/download_storage_utils.dart';

void main() {
  group('DownloadStorageUtils', () {
    group('formatBytes', () {
      test('formats 0 bytes correctly', () {
        expect(DownloadStorageUtils.formatBytes(0), '0 B');
      });

      test('formats negative bytes as 0', () {
        expect(DownloadStorageUtils.formatBytes(-100), '0 B');
      });

      test('formats bytes correctly', () {
        expect(DownloadStorageUtils.formatBytes(500), '500.0 B');
      });

      test('formats kilobytes correctly', () {
        expect(DownloadStorageUtils.formatBytes(1024), '1.0 KB');
        expect(DownloadStorageUtils.formatBytes(1536), '1.5 KB');
      });

      test('formats megabytes correctly', () {
        expect(DownloadStorageUtils.formatBytes(1024 * 1024), '1.0 MB');
        expect(DownloadStorageUtils.formatBytes(5 * 1024 * 1024), '5.0 MB');
      });

      test('formats gigabytes correctly', () {
        expect(DownloadStorageUtils.formatBytes(1024 * 1024 * 1024), '1.0 GB');
        expect(
            DownloadStorageUtils.formatBytes(2 * 1024 * 1024 * 1024), '2.0 GB');
      });

      test('formats terabytes correctly', () {
        expect(DownloadStorageUtils.formatBytes(1024 * 1024 * 1024 * 1024),
            '1.0 TB');
      });
    });

    // Note: File system methods like getDownloadsDirectory, getDirectorySize,
    // cleanupTempFiles, readLocalMetadata, and getDownloadedImagePaths
    // require integration tests with actual file system access.
    // These are best tested with mocking or in integration test environment.
  });
}
