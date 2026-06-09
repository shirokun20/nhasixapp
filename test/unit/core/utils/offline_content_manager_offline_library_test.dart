import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:nhasixapp/core/utils/offline_content_manager.dart';
import 'package:nhasixapp/domain/entities/download_status.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';

class MockUserDataRepository extends Mock implements UserDataRepository {}

void main() {
  group('OfflineContentManager offline library helpers', () {
    late MockUserDataRepository userDataRepository;
    late OfflineContentManager manager;
    late Directory tempDir;

    setUpAll(() {
      registerFallbackValue(
        const DownloadStatus(
          contentId: 'fallback',
          state: DownloadState.completed,
        ),
      );
    });

    setUp(() async {
      userDataRepository = MockUserDataRepository();
      manager = OfflineContentManager(
        userDataRepository: userDataRepository,
        logger: Logger(level: Level.off),
      );
      tempDir = await Directory.systemTemp.createTemp(
        'offline-library-manager-',
      );

      when(() => userDataRepository.getDownloadStatus(any()))
          .thenAnswer((_) async => null);
      when(
        () => userDataRepository.getAllDownloads(
          state: any(named: 'state'),
          sourceId: any(named: 'sourceId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          orderBy: any(named: 'orderBy'),
          descending: any(named: 'descending'),
        ),
      ).thenAnswer((_) async => const <DownloadStatus>[]);
      when(() => userDataRepository.saveDownloadStatus(any()))
          .thenAnswer((_) async {});
      when(() => userDataRepository.deleteDownloadStatus(any()))
          .thenAnswer((_) async {});
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('preserves unknown source folders and maps legacy folders to local',
        () {
      expect(
        manager.resolveStoredSourceId(
          contentPath: path.join('/tmp', 'nhasix', 'mangafire', 'chapter-1'),
        ),
        'mangafire',
      );

      expect(
        manager.resolveStoredSourceId(
          contentPath: path.join('/tmp', 'nhasix', 'legacy-gallery'),
        ),
        'local',
      );

      expect(
        manager.resolveStoredSourceId(
          metadata: const {'source_id': 'komikcast-old'},
          contentPath: path.join('/tmp', 'nhasix', 'legacy-gallery'),
        ),
        'komikcast-old',
      );
    });

    test('image-count resolver prefers metadata then falls back to image files',
        () async {
      final contentDir = Directory(path.join(tempDir.path, 'gallery-count'));
      await _writeImage(contentDir, 'page_001.jpg');
      await _writeImage(contentDir, 'page_002.png');
      await _writeImage(contentDir, 'page_003.webp');

      final metadataCount = await manager.resolveOfflineImageCount(
        contentPath: contentDir.path,
        metadata: const {'pageCount': 12},
      );
      final fileCount = await manager.resolveOfflineImageCount(
        contentPath: contentDir.path,
      );

      expect(metadataCount, 12);
      expect(fileCount, 3);
    });

    test('storage path resolver falls back from download path to image path',
        () async {
      final contentDir = Directory(path.join(tempDir.path, 'gallery-path'));
      final imageFile = await _writeImage(contentDir, 'page_001.jpg');

      final fromDownloadPath = await manager.resolveOfflineStoragePath(
        downloadPath: contentDir.path,
      );
      final fromImagePath = await manager.resolveOfflineStoragePath(
        downloadPath: path.join(tempDir.path, 'missing'),
        contentPath: path.join(tempDir.path, 'also-missing'),
        imageUrls: [imageFile.path],
      );

      expect(fromDownloadPath, contentDir.path);
      expect(fromImagePath, contentDir.path);
    });

    test(
        'scanBackupFolder discovers manual content and uninstalled source roots while skipping broken folders',
        () async {
      final root = Directory(path.join(tempDir.path, 'nhasix'));
      await root.create(recursive: true);

      final manualDir = Directory(path.join(root.path, 'manual-gallery'));
      await _writeImage(manualDir, 'page_001.jpg');
      await _writeImage(manualDir, 'page_002.jpg');

      final brokenDir = Directory(path.join(root.path, 'broken-gallery'));
      await brokenDir.create(recursive: true);
      await File(path.join(brokenDir.path, 'metadata.json')).writeAsString(
        jsonEncode({'id': 'broken-gallery'}),
      );

      final otherSourceDir = Directory(path.join(root.path, 'mangafire'));
      final chapterDir = Directory(path.join(otherSourceDir.path, 'chapter-1'));
      await _writeImage(chapterDir, 'page_001.jpg');
      await File(path.join(chapterDir.path, 'metadata.json')).writeAsString(
        jsonEncode({
          'id': 'chapter-1',
          'title': 'Chapter One',
          'source': 'mangafire',
        }),
      );

      final contents = await manager.scanBackupFolder(root.path);

      expect(contents.map((content) => content.id).toList(),
          contains('manual-gallery'));
      expect(contents.map((content) => content.id).toList(),
          contains('chapter-1'));
      expect(contents.map((content) => content.id).toList(),
          isNot(contains('broken-gallery')));

      final manualMetadata = jsonDecode(
        await File(path.join(manualDir.path, 'metadata.json')).readAsString(),
      ) as Map<String, dynamic>;
      expect(manualMetadata['source'], 'local');

      final otherContent =
          contents.firstWhere((content) => content.id == 'chapter-1');
      expect(otherContent.sourceId, 'mangafire');
      expect(otherContent.title, 'Chapter One');
    });

    test(
        'syncBackupToDatabase repairs stale source ids from filesystem truth without remapping unknown source roots',
        () async {
      final root = Directory(path.join(tempDir.path, 'nhasix'));
      final otherSourceDir = Directory(path.join(root.path, 'mangafire'));
      final contentDir = Directory(path.join(otherSourceDir.path, 'series-1'));
      await _writeImage(contentDir, 'page_001.jpg');
      await File(path.join(contentDir.path, 'metadata.json')).writeAsString(
        jsonEncode({
          'id': 'series-1',
          'title': 'Series One',
          'source': 'mangafire',
        }),
      );

      final savedStatuses = <DownloadStatus>[];
      when(() => userDataRepository.getDownloadStatus('series-1')).thenAnswer(
        (_) async => DownloadStatus(
          contentId: 'series-1',
          state: DownloadState.completed,
          title: 'Series One',
          sourceId: 'nhentai',
          totalPages: 1,
          downloadPath: contentDir.path,
        ),
      );
      when(() => userDataRepository.saveDownloadStatus(any())).thenAnswer(
        (invocation) async {
          savedStatuses
              .add(invocation.positionalArguments.first as DownloadStatus);
        },
      );

      final result = await manager.syncBackupToDatabase(root.path);

      expect(result['updated'], 1);
      expect(savedStatuses.single.sourceId, 'mangafire');
    });

    test(
        'syncBackupToDatabase rekeys legacy safe-id rows instead of duplicating',
        () async {
      final root = Directory(path.join(tempDir.path, 'nhasix'));
      final sourceDir = Directory(path.join(root.path, 'komiku'));
      final contentDir = Directory(path.join(sourceDir.path, '2qbiiejj4x'));
      await _writeImage(contentDir, 'page_001.webp');
      await File(path.join(contentDir.path, 'metadata.json')).writeAsString(
        jsonEncode({
          'id': 'chapter-72-original-id',
          'title': 'Chapter 72',
          'source': 'komiku',
        }),
      );

      final savedStatuses = <DownloadStatus>[];
      when(
        () => userDataRepository.getAllDownloads(
          state: any(named: 'state'),
          sourceId: any(named: 'sourceId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
          orderBy: any(named: 'orderBy'),
          descending: any(named: 'descending'),
        ),
      ).thenAnswer(
        (_) async => [
          DownloadStatus(
            contentId: '2qbiiejj4x',
            state: DownloadState.completed,
            title: 'Chapter 72',
            sourceId: 'komiku',
            totalPages: 1,
            downloadedPages: 1,
            downloadPath: contentDir.path,
          ),
        ],
      );
      when(() => userDataRepository.saveDownloadStatus(any())).thenAnswer(
        (invocation) async => savedStatuses
            .add(invocation.positionalArguments.first as DownloadStatus),
      );

      final result = await manager.syncBackupToDatabase(root.path);

      expect(result['synced'], 0);
      expect(result['updated'], 1);
      expect(savedStatuses.single.contentId, 'chapter-72-original-id');
      verify(() => userDataRepository.deleteDownloadStatus('2qbiiejj4x'))
          .called(1);
    });
  });
}

Future<File> _writeImage(Directory contentDir, String fileName) async {
  final imagesDir = Directory(path.join(contentDir.path, 'images'));
  await imagesDir.create(recursive: true);
  final file = File(path.join(imagesDir.path, fileName));
  return file.writeAsBytes(const <int>[1, 2, 3, 4]);
}
