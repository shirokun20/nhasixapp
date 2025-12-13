import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/constants/app_constants.dart';

void main() {
  group('AppLimits', () {
    test('defaultPageSize is reasonable', () {
      expect(AppLimits.defaultPageSize, greaterThan(0));
      expect(AppLimits.defaultPageSize, lessThanOrEqualTo(50));
    });

    test('maxBatchSize is larger than defaultPageSize', () {
      expect(AppLimits.maxBatchSize, greaterThan(AppLimits.defaultPageSize));
    });

    test('defaultPage is 1', () {
      expect(AppLimits.defaultPage, 1);
    });

    test('maxConcurrentDownloads is reasonable', () {
      expect(AppLimits.maxConcurrentDownloads, greaterThan(0));
      expect(AppLimits.maxConcurrentDownloads, lessThanOrEqualTo(10));
    });

    test('searchHistoryLimit is positive', () {
      expect(AppLimits.searchHistoryLimit, greaterThan(0));
    });

    test('imagePreloadBuffer is positive', () {
      expect(AppLimits.imagePreloadBuffer, greaterThan(0));
    });
  });

  group('AppDurations', () {
    test('splashDelay is not too long', () {
      expect(AppDurations.splashDelay.inSeconds, lessThanOrEqualTo(5));
    });

    test('snackbar durations are reasonable', () {
      expect(AppDurations.snackbarShort.inSeconds,
          lessThan(AppDurations.snackbarLong.inSeconds));
    });

    test('searchDebounce is reasonable', () {
      expect(AppDurations.searchDebounce.inMilliseconds,
          greaterThanOrEqualTo(100));
      expect(
          AppDurations.searchDebounce.inMilliseconds, lessThanOrEqualTo(1000));
    });

    test('networkTimeout is reasonable', () {
      expect(AppDurations.networkTimeout.inSeconds, greaterThanOrEqualTo(10));
      expect(AppDurations.networkTimeout.inSeconds, lessThanOrEqualTo(120));
    });

    test('cacheExpiration is at least 1 hour', () {
      expect(AppDurations.cacheExpiration.inHours, greaterThanOrEqualTo(1));
    });
  });

  group('AppStorage', () {
    test('backupFolderName is not empty', () {
      expect(AppStorage.backupFolderName, isNotEmpty);
    });

    test('metadataFileName ends with .json', () {
      expect(AppStorage.metadataFileName.endsWith('.json'), true);
    });

    test('imagesSubfolder is not empty', () {
      expect(AppStorage.imagesSubfolder, isNotEmpty);
    });

    test('maxImageSizeKb is reasonable', () {
      expect(AppStorage.maxImageSizeKb, greaterThan(0));
      expect(AppStorage.maxImageSizeKb, lessThanOrEqualTo(1000));
    });
  });

  group('AppUI', () {
    test('gridColumnsPortrait is greater than 0', () {
      expect(AppUI.gridColumnsPortrait, greaterThan(0));
    });

    test('gridColumnsLandscape is greater than portrait', () {
      expect(AppUI.gridColumnsLandscape,
          greaterThanOrEqualTo(AppUI.gridColumnsPortrait));
    });

    test('minCardWidth is positive', () {
      expect(AppUI.minCardWidth, greaterThan(0));
    });

    test('cardAspectRatio is reasonable', () {
      expect(AppUI.cardAspectRatio, greaterThan(0));
      expect(AppUI.cardAspectRatio, lessThan(2));
    });

    test('cardBorderRadius is positive', () {
      expect(AppUI.cardBorderRadius, greaterThan(0));
    });

    test('defaultPadding is positive', () {
      expect(AppUI.defaultPadding, greaterThan(0));
    });

    test('titleMaxLength is positive', () {
      expect(AppUI.titleMaxLength, greaterThan(0));
    });
  });

  group('AppConfig', () {
    test('minAndroidSdk is at least API 21', () {
      expect(AppConfig.minAndroidSdk, greaterThanOrEqualTo(21));
    });

    test('feature flags are boolean', () {
      expect(AppConfig.enablePerformanceMonitoring, isA<bool>());
      expect(AppConfig.enableAnalytics, isA<bool>());
    });
  });
}
