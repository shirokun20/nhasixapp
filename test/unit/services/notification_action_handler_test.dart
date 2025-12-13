import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:nhasixapp/services/notifications/notification_action_handler.dart';
import 'package:nhasixapp/services/notifications/notification_constants.dart';

void main() {
  late NotificationActionHandler handler;
  late Logger logger;
  late List<String> callLog;

  setUp(() {
    logger = Logger(level: Level.off);
    callLog = [];
    handler = NotificationActionHandler(
      logger: logger,
      onDownloadPause: (id) => callLog.add('pause:$id'),
      onDownloadResume: (id) => callLog.add('resume:$id'),
      onDownloadCancel: (id) => callLog.add('cancel:$id'),
      onDownloadRetry: (id) => callLog.add('retry:$id'),
      onPdfRetry: (id) => callLog.add('pdfRetry:$id'),
      onOpenDownload: (id) => callLog.add('open:$id'),
      onNavigateToDownloads: (id) => callLog.add('navigate:$id'),
    );
  });

  group('NotificationActionHandler', () {
    group('handleAction', () {
      test('handles pause action', () {
        final result = handler.handleAction(
          actionId: NotificationActions.pause,
          payload: 'content123',
        );
        expect(result, true);
        expect(callLog, contains('pause:content123'));
      });

      test('handles resume action', () {
        final result = handler.handleAction(
          actionId: NotificationActions.resume,
          payload: 'content123',
        );
        expect(result, true);
        expect(callLog, contains('resume:content123'));
      });

      test('handles cancel action', () {
        final cancelNotificationCalled = <String>[];
        final result = handler.handleAction(
          actionId: NotificationActions.cancel,
          payload: 'content123',
          onCancelNotification: (id) => cancelNotificationCalled.add(id),
        );
        expect(result, true);
        expect(callLog, contains('cancel:content123'));
        expect(cancelNotificationCalled, contains('content123'));
      });

      test('handles retry action', () {
        final result = handler.handleAction(
          actionId: NotificationActions.retry,
          payload: 'content123',
        );
        expect(result, true);
        expect(callLog, contains('retry:content123'));
      });

      test('handles open action', () {
        final result = handler.handleAction(
          actionId: NotificationActions.open,
          payload: 'content123',
        );
        expect(result, true);
        expect(callLog, contains('open:content123'));
      });

      test('handles retry PDF action', () {
        final result = handler.handleAction(
          actionId: NotificationActions.retryPdf,
          payload: 'content123',
        );
        expect(result, true);
        expect(callLog, contains('pdfRetry:content123'));
      });

      test('handles default tap with navigation', () {
        final result = handler.handleAction(
          actionId: null,
          payload: 'content123',
        );
        expect(result, true);
        expect(callLog, contains('navigate:content123'));
      });

      test('returns false with null payload', () {
        final result = handler.handleAction(
          actionId: NotificationActions.pause,
          payload: null,
        );
        expect(result, false);
        expect(callLog, isEmpty);
      });

      test('returns false for unknown action', () {
        final result = handler.handleAction(
          actionId: 'unknown_action',
          payload: 'content123',
        );
        expect(result, false);
      });
    });

    group('setCallbacks', () {
      test('updates callbacks correctly', () {
        final newCallLog = <String>[];
        handler.setCallbacks(
          onDownloadPause: (id) => newCallLog.add('newPause:$id'),
        );

        handler.handleAction(
          actionId: NotificationActions.pause,
          payload: 'test',
        );

        expect(newCallLog, contains('newPause:test'));
      });
    });
  });

  group('NotificationConstants', () {
    test('NotificationChannels has correct values', () {
      expect(NotificationChannels.downloadChannelId, 'download_channel');
      expect(NotificationChannels.pdfChannelId, 'pdf_conversion_channel');
    });

    test('NotificationActions has correct values', () {
      expect(NotificationActions.pause, 'pause');
      expect(NotificationActions.resume, 'resume');
      expect(NotificationActions.cancel, 'cancel');
      expect(NotificationActions.openPdf, 'open_pdf');
      expect(NotificationActions.sharePdf, 'share_pdf');
    });

    test('NotificationIdRanges has correct values', () {
      expect(NotificationIdRanges.downloadBase, 0);
      expect(NotificationIdRanges.pdfBase, 100000);
      expect(NotificationIdRanges.generalBase, 200000);
    });

    test('NotificationLimits has correct values', () {
      expect(NotificationLimits.maxTitleLength, 40);
      expect(NotificationLimits.maxErrorLength, 100);
    });

    test('NotificationPayloadKeys has correct values', () {
      expect(NotificationPayloadKeys.contentId, 'contentId');
      expect(NotificationPayloadKeys.typePdf, 'pdf');
    });
  });
}
