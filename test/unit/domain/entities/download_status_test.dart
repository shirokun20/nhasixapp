import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/domain/entities/download_status.dart';

void main() {
  group('DownloadStatus Entity', () {
    group('progress calculation', () {
      test('returns 0.0 when totalPages is 0', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.downloading,
          downloadedPages: 0,
          totalPages: 0,
        );
        expect(status.progress, 0.0);
      });

      test('calculates progress correctly', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.downloading,
          downloadedPages: 25,
          totalPages: 100,
        );
        expect(status.progress, 0.25);
        expect(status.progressPercentage, 25);
      });

      test('caps progress at 1.0', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.downloading,
          downloadedPages: 110,
          totalPages: 100,
        );
        expect(status.progress, 1.0);
      });

      test('calculates progress for range download', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.downloading,
          downloadedPages: 5,
          totalPages: 100,
          startPage: 1,
          endPage: 10,
        );
        // 5 out of 10 pages (range) = 50%
        expect(status.progress, 0.5);
        expect(status.pagesToDownload, 10);
      });
    });

    group('range download properties', () {
      test('isRangeDownload returns true when start and end defined', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.queued,
          startPage: 1,
          endPage: 10,
          totalPages: 100,
        );
        expect(status.isRangeDownload, true);
        expect(status.effectiveStartPage, 1);
        expect(status.effectiveEndPage, 10);
      });

      test('isRangeDownload returns false when no range', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.queued,
          totalPages: 100,
        );
        expect(status.isRangeDownload, false);
        expect(status.effectiveStartPage, 1);
        expect(status.effectiveEndPage, 100);
      });

      test('rangeDisplayText shows correct format', () {
        const rangeStatus = DownloadStatus(
          contentId: '123',
          state: DownloadState.queued,
          startPage: 10,
          endPage: 20,
          totalPages: 100,
        );
        expect(rangeStatus.rangeDisplayText, 'Pages 10-20 of 100');

        const fullStatus = DownloadStatus(
          contentId: '123',
          state: DownloadState.queued,
          totalPages: 50,
        );
        expect(fullStatus.rangeDisplayText, 'All pages (50)');
      });
    });

    group('state checks', () {
      test('isInProgress returns true for downloading state', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.downloading,
        );
        expect(status.isInProgress, true);
        expect(status.isCompleted, false);
      });

      test('isCompleted returns true for completed state', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.completed,
        );
        expect(status.isCompleted, true);
        expect(status.isInProgress, false);
      });

      test('isFailed returns true for failed state', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.failed,
          error: 'Network error',
        );
        expect(status.isFailed, true);
      });

      test('isPaused returns true for paused state', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.paused,
        );
        expect(status.isPaused, true);
      });

      test('isQueued returns true for queued state', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.queued,
        );
        expect(status.isQueued, true);
      });

      test('isCancelled returns true for cancelled state', () {
        const status = DownloadStatus(
          contentId: '123',
          state: DownloadState.cancelled,
        );
        expect(status.isCancelled, true);
      });
    });

    group('action availability', () {
      test('canResume is true for paused and failed', () {
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.paused)
              .canResume,
          true,
        );
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.failed)
              .canResume,
          true,
        );
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.downloading)
              .canResume,
          false,
        );
      });

      test('canPause is true for downloading and queued', () {
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.downloading)
              .canPause,
          true,
        );
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.queued)
              .canPause,
          true,
        );
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.completed)
              .canPause,
          false,
        );
      });

      test('canCancel is false for completed and cancelled', () {
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.completed)
              .canCancel,
          false,
        );
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.cancelled)
              .canCancel,
          false,
        );
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.downloading)
              .canCancel,
          true,
        );
      });

      test('canRetry is true for failed and cancelled', () {
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.failed)
              .canRetry,
          true,
        );
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.cancelled)
              .canRetry,
          true,
        );
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.completed)
              .canRetry,
          false,
        );
      });
    });

    group('formatting', () {
      test('formattedFileSize formats bytes correctly', () {
        expect(
          const DownloadStatus(
                  contentId: '1', state: DownloadState.completed, fileSize: 0)
              .formattedFileSize,
          '0 B',
        );
        expect(
          const DownloadStatus(
                  contentId: '1', state: DownloadState.completed, fileSize: 512)
              .formattedFileSize,
          '512.0 B',
        );
        expect(
          const DownloadStatus(
                  contentId: '1',
                  state: DownloadState.completed,
                  fileSize: 1024)
              .formattedFileSize,
          '1.0 KB',
        );
        expect(
          const DownloadStatus(
                  contentId: '1',
                  state: DownloadState.completed,
                  fileSize: 1048576)
              .formattedFileSize,
          '1.0 MB',
        );
      });

      test('formattedSpeed formats speed correctly', () {
        expect(
          const DownloadStatus(
                  contentId: '1', state: DownloadState.downloading, speed: 0)
              .formattedSpeed,
          '0 B/s',
        );
        expect(
          const DownloadStatus(
                  contentId: '1', state: DownloadState.downloading, speed: 1024)
              .formattedSpeed,
          '1.0 KB/s',
        );
        expect(
          const DownloadStatus(
                  contentId: '1',
                  state: DownloadState.downloading,
                  speed: 2097152)
              .formattedSpeed,
          '2.0 MB/s',
        );
      });

      test('statusText returns correct text for each state', () {
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.queued)
              .statusText,
          'Queued',
        );
        expect(
          const DownloadStatus(
            contentId: '1',
            state: DownloadState.downloading,
            downloadedPages: 50,
            totalPages: 100,
          ).statusText,
          'Downloading (50%)',
        );
        expect(
          const DownloadStatus(contentId: '1', state: DownloadState.completed)
              .statusText,
          'Completed',
        );
      });
    });

    group('factory constructors', () {
      test('initial creates queued status', () {
        final status = DownloadStatus.initial('123', 100);
        expect(status.contentId, '123');
        expect(status.state, DownloadState.queued);
        expect(status.totalPages, 100);
        expect(status.startTime, isNotNull);
      });

      test('initial with range creates ranged status', () {
        final status =
            DownloadStatus.initial('123', 100, startPage: 10, endPage: 20);
        expect(status.isRangeDownload, true);
        expect(status.startPage, 10);
        expect(status.endPage, 20);
      });

      test('completed creates completed status', () {
        final status =
            DownloadStatus.completed('123', 100, '/path/to/download', 1048576);
        expect(status.state, DownloadState.completed);
        expect(status.downloadedPages, 100);
        expect(status.downloadPath, '/path/to/download');
        expect(status.fileSize, 1048576);
      });

      test('failed creates failed status', () {
        final status = DownloadStatus.failed('123', 'Connection timeout');
        expect(status.state, DownloadState.failed);
        expect(status.error, 'Connection timeout');
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        const original = DownloadStatus(
          contentId: '123',
          state: DownloadState.downloading,
          downloadedPages: 10,
          totalPages: 100,
        );

        final copy = original.copyWith(
          state: DownloadState.paused,
          downloadedPages: 25,
        );

        expect(copy.state, DownloadState.paused);
        expect(copy.downloadedPages, 25);
        expect(copy.contentId, '123'); // unchanged
        expect(copy.totalPages, 100); // unchanged
      });
    });
  });

  group('DownloadState Extension', () {
    test('displayName returns correct names', () {
      expect(DownloadState.queued.displayName, 'Queued');
      expect(DownloadState.downloading.displayName, 'Downloading');
      expect(DownloadState.paused.displayName, 'Paused');
      expect(DownloadState.completed.displayName, 'Completed');
      expect(DownloadState.failed.displayName, 'Failed');
      expect(DownloadState.cancelled.displayName, 'Cancelled');
    });

    test('isActive is true for downloading and queued', () {
      expect(DownloadState.downloading.isActive, true);
      expect(DownloadState.queued.isActive, true);
      expect(DownloadState.paused.isActive, false);
      expect(DownloadState.completed.isActive, false);
    });

    test('isTerminal is true for completed, failed, cancelled', () {
      expect(DownloadState.completed.isTerminal, true);
      expect(DownloadState.failed.isTerminal, true);
      expect(DownloadState.cancelled.isTerminal, true);
      expect(DownloadState.downloading.isTerminal, false);
      expect(DownloadState.queued.isTerminal, false);
    });

    test('canRetry is true for failed and cancelled', () {
      expect(DownloadState.failed.canRetry, true);
      expect(DownloadState.cancelled.canRetry, true);
      expect(DownloadState.completed.canRetry, false);
    });
  });
}
