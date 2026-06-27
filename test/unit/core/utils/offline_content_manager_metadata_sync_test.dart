import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/domain/entities/download_status.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';

class MockUserDataRepository extends Mock implements UserDataRepository {}

void _registerFallbacks() {
  registerFallbackValue(
    const DownloadStatus(
      contentId: 'fallback',
      state: DownloadState.completed,
    ),
  );
}

void main() {
  group('OfflineContentManager metadata reconciliation', () {
    late MockUserDataRepository userDataRepository;
    late OfflineContentManager manager;
    late Directory tempDir;

    setUpAll(_registerFallbacks);

    setUp(() async {
      userDataRepository = MockUserDataRepository();
      manager = OfflineContentManager(
        userDataRepository: userDataRepository,
        logger: Logger(level: Level.off),
      );

      tempDir = await Directory.systemTemp.createTemp('offline-meta-sync-');

      when(() => userDataRepository.getDownloadStatus(any())).thenAnswer(
        (invocation) async {
          final contentId = invocation.positionalArguments.first as String;
          return DownloadStatus(
            contentId: contentId,
            state: DownloadState.completed,
            downloadPath: tempDir.path,
          );
        },
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<void> writeMetadata(Map<String, dynamic> payload) {
      final metadataFile = File('${tempDir.path}/metadata.json');
      return metadataFile.writeAsString(jsonEncode(payload));
    }

    Future<Map<String, dynamic>> readMetadata() async {
      final metadataFile = File('${tempDir.path}/metadata.json');
      return jsonDecode(await metadataFile.readAsString())
          as Map<String, dynamic>;
    }

    Future<void> writeValidPngPage(int pageNumber) async {
      final imagesDir = Directory('${tempDir.path}/images');
      await imagesDir.create(recursive: true);
      final file = File(
        '${imagesDir.path}/page_${pageNumber.toString().padLeft(3, '0')}.png',
      );
      await file.writeAsBytes(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);
    }

    test('removeFailedPageFromMetadata uses valid-file reconciliation rule',
        () async {
      await writeMetadata({
        'id': 'gallery-1',
        'failed_pages': [
          {'page': 2, 'url': 'https://img.example/2.webp'},
          {'page': 5, 'url': 'https://img.example/5.webp'},
        ],
      });
      await writeValidPngPage(2);

      await manager.removeFailedPageFromMetadata('gallery-1', 2);

      final metadata = await readMetadata();
      final failedPages = (metadata['failed_pages'] as List)
          .cast<Map<String, dynamic>>()
          .map((entry) => entry['page'])
          .toList();
      expect(failedPages, [5]);
    });

    test('download completion reconciliation removes stale failed markers only',
        () async {
      await writeMetadata({
        'id': 'gallery-2',
        'failed_pages': [
          {'page': 1, 'url': 'https://img.example/1.webp'},
          {'page': 2, 'url': 'https://img.example/2.webp'},
          {'page': 3, 'url': 'https://img.example/3.webp'},
        ],
      });
      await writeValidPngPage(1);
      await writeValidPngPage(3);

      await manager.reconcileChapterMetadataForCompletedDownload(
        contentId: 'gallery-2',
        contentPath: tempDir.path,
      );

      final metadata = await readMetadata();
      final failedPages = (metadata['failed_pages'] as List)
          .cast<Map<String, dynamic>>()
          .map((entry) => entry['page'])
          .toList();
      expect(failedPages, [2]);
    });

    test('repair then completion sequence converges to filesystem truth',
        () async {
      await writeMetadata({
        'id': 'gallery-3',
        'failed_pages': [
          {'page': 4, 'url': 'https://img.example/4.webp'},
        ],
      });

      await manager.reconcileChapterMetadataPage(
        contentId: 'gallery-3',
        pageNumber: 4,
        sourceUrl: 'https://img.example/4.webp',
      );

      await writeValidPngPage(4);

      await manager.reconcileChapterMetadataForCompletedDownload(
        contentId: 'gallery-3',
        contentPath: tempDir.path,
      );

      final metadata = await readMetadata();
      expect(metadata['failed_pages'], isEmpty);
    });

    test('syncBackupToDatabase clears local rows before local-only resync',
        () async {
      final localContentDir =
          Directory('${tempDir.path}/local/new-local-content/images');
      await localContentDir.create(recursive: true);
      await File('${localContentDir.path}/page_001.png').writeAsBytes(
        <int>[
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ],
      );

      when(() => userDataRepository.getDownloadStatus(any()))
          .thenAnswer((_) async => null);
      when(() => userDataRepository.getDownloadsCount(
            state: DownloadState.completed,
            sourceId: 'local',
          )).thenAnswer((_) async => 1);
      when(() => userDataRepository.getAllDownloads(
            state: DownloadState.completed,
            sourceId: 'local',
            limit: 1,
            offset: 0,
            orderBy: 'created_at',
            descending: true,
          )).thenAnswer((_) async => [
            DownloadStatus.completed(
              'stale-local',
              1,
              '/stale/path',
              0,
              sourceId: 'local',
            ),
          ]);
      when(() => userDataRepository.deleteDownloadStatus('stale-local'))
          .thenAnswer((_) async {});
      when(() => userDataRepository.saveDownloadStatus(any()))
          .thenAnswer((_) async {});

      final result = await manager.syncBackupToDatabase(
        tempDir.path,
        sourceId: 'local',
      );

      expect(result['synced'], 1);
      expect(result['updated'], 0);
      verify(() => userDataRepository.deleteDownloadStatus('stale-local'))
          .called(1);
      verify(() => userDataRepository.saveDownloadStatus(any())).called(1);
    });

    test('syncBackupToDatabase restores native metadata content_id as DB id',
        () async {
      final chapterDir = Directory(
        '${tempDir.path}/komiktap/10vlmmznl1/images',
      );
      await chapterDir.create(recursive: true);
      await File('${chapterDir.path}/page_001.png').writeAsBytes(
        <int>[
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ],
      );
      await File('${tempDir.path}/komiktap/10vlmmznl1/metadata.json')
          .writeAsString(
        jsonEncode({
          'schemaVersion': '2.1',
          'source': 'komiktap',
          'content_id': 'sakare-seishun-ragai-katsudou-chapter-6',
          'title': 'sakare-seishun-ragai-katsudou-chapter-6',
          'cover_url': '',
        }),
      );

      when(() => userDataRepository.getDownloadStatus(any()))
          .thenAnswer((_) async => null);
      when(() => userDataRepository.getDownloadsCount(
            state: DownloadState.completed,
            sourceId: null,
          )).thenAnswer((_) async => 0);
      when(() => userDataRepository.saveDownloadStatus(any()))
          .thenAnswer((_) async {});

      final result = await manager.syncBackupToDatabase(tempDir.path);

      expect(result['synced'], 1);

      final captured = verify(
        () => userDataRepository.saveDownloadStatus(captureAny()),
      ).captured.single as DownloadStatus;
      expect(captured.contentId, 'sakare-seishun-ragai-katsudou-chapter-6');
      expect(captured.sourceId, 'komiktap');
      expect(captured.title, 'sakare-seishun-ragai-katsudou-chapter-6');
    });

    test('syncBackupToDatabase replaces stale hashed DB row on full resync',
        () async {
      final chapterRoot = Directory('${tempDir.path}/crotpedia/11k38msg3d');
      final chapterDir = Directory('${chapterRoot.path}/images');
      await chapterDir.create(recursive: true);
      await File('${chapterDir.path}/page_001.jpg').writeAsBytes(<int>[1, 2, 3]);
      await File('${chapterRoot.path}/metadata.json').writeAsString(
        jsonEncode({
          'schemaVersion': '2.1',
          'source': 'crotpedia',
          'content_id': 'frust-rei-chan-chapter-1-bahasa-indonesia',
          'title': 'Frust Rei-chan - Chapter 1',
        }),
      );

      when(() => userDataRepository.getDownloadStatus(any()))
          .thenAnswer((_) async => null);
      when(() => userDataRepository.getDownloadsCount(
            state: DownloadState.completed,
            sourceId: null,
          )).thenAnswer((_) async => 1);
      when(() => userDataRepository.getAllDownloads(
            state: DownloadState.completed,
            sourceId: null,
            limit: 1,
            offset: 0,
            orderBy: 'created_at',
            descending: true,
          )).thenAnswer((_) async => [
            DownloadStatus.completed(
              '11k38msg3d',
              32,
              chapterRoot.path,
              123,
              sourceId: 'crotpedia',
            ),
          ]);
      when(() => userDataRepository.saveDownloadStatus(any()))
          .thenAnswer((_) async {});
      when(() => userDataRepository.deleteDownloadStatus('11k38msg3d'))
          .thenAnswer((_) async {});

      final result = await manager.syncBackupToDatabase(tempDir.path);

      expect(result['synced'], 1);
      expect(result['updated'], 0);

      final captured = verify(
        () => userDataRepository.saveDownloadStatus(captureAny()),
      ).captured.single as DownloadStatus;
      expect(captured.contentId, 'frust-rei-chan-chapter-1-bahasa-indonesia');
      expect(captured.sourceId, 'crotpedia');
      verify(() => userDataRepository.deleteDownloadStatus('11k38msg3d'))
          .called(1);
    });
  });
}
