import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/core/constants/app_constants.dart';
import 'package:nhasixapp/core/di/service_locator.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';
import 'package:nhasixapp/domain/usecases/downloads/download_content_usecase.dart';
import 'package:nhasixapp/services/native_download_service.dart';
import 'package:nhasixapp/services/pdf_service.dart';

class MockUserDataRepository extends Mock implements UserDataRepository {}

class MockNativeDownloadService extends Mock implements NativeDownloadService {}

class MockPdfService extends Mock implements PdfService {}

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

void main() {
  late MockUserDataRepository userDataRepository;
  late MockNativeDownloadService nativeDownloadService;
  late MockPdfService pdfService;
  late MockRemoteConfigService remoteConfigService;
  late DownloadContentUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      const DownloadStatus(
        contentId: 'fallback',
        state: DownloadState.queued,
      ),
    );
  });

  setUp(() {
    userDataRepository = MockUserDataRepository();
    nativeDownloadService = MockNativeDownloadService();
    pdfService = MockPdfService();
    remoteConfigService = MockRemoteConfigService();
    useCase = DownloadContentUseCase(
      userDataRepository,
      nativeDownloadService,
      pdfService,
      logger: Logger(),
    );

    if (getIt.isRegistered<RemoteConfigService>()) {
      getIt.unregister<RemoteConfigService>();
    }
    when(() => remoteConfigService.appConfig).thenReturn(null);
    getIt.registerSingleton<RemoteConfigService>(remoteConfigService);

    when(() => userDataRepository.getDownloadStatus(any()))
        .thenAnswer((_) async => null);
    when(() => userDataRepository.saveDownloadStatus(any()))
        .thenAnswer((_) async {});
    when(
      () => nativeDownloadService.startDownload(
        contentId: any(named: 'contentId'),
        sourceId: any(named: 'sourceId'),
        imageUrls: any(named: 'imageUrls'),
        destinationPath: any(named: 'destinationPath'),
        cookies: any(named: 'cookies'),
        headers: any(named: 'headers'),
        title: any(named: 'title'),
        url: any(named: 'url'),
        coverUrl: any(named: 'coverUrl'),
        language: any(named: 'language'),
        startPage: any(named: 'startPage'),
        endPage: any(named: 'endPage'),
        totalPages: any(named: 'totalPages'),
        enableNotifications: any(named: 'enableNotifications'),
        backupFolderName: any(named: 'backupFolderName'),
        maxParallelImages: any(named: 'maxParallelImages'),
        imageTimeoutMs: any(named: 'imageTimeoutMs'),
      ),
    ).thenAnswer((_) async => 'work-1');
  });

  tearDown(() async {
    if (getIt.isRegistered<RemoteConfigService>()) {
      await getIt.unregister<RemoteConfigService>();
    }
  });

  test(
      'passes sliced URLs and original page numbering to native layer for range download',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'download-content-usecase-test',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final content = Content(
      id: '3902890/a3cd1a97d6',
      title: 'Test E-Hentai Range',
      coverUrl: 'https://ehgt.org/w/test-cover.webp',
      pageCount: 5,
      imageUrls: const <String>[
        'https://e-hentai.org/s/hash/3902890-1',
        'https://e-hentai.org/s/hash/3902890-2',
        'https://e-hentai.org/s/hash/3902890-3',
        'https://e-hentai.org/s/hash/3902890-4',
        'https://e-hentai.org/s/hash/3902890-5',
      ],
      tags: const <Tag>[],
      artists: const <String>[],
      characters: const <String>[],
      parodies: const <String>[],
      groups: const <String>[],
      language: 'unknown',
      url: 'https://e-hentai.org/g/3902890/a3cd1a97d6/',
      uploadDate: DateTime(2026, 4, 26),
      favorites: 0,
      sourceId: 'ehentai',
    );

    await useCase.call(
      DownloadContentParams.immediate(
        content,
        startPage: 2,
        endPage: 4,
        savePath: tempDir.path,
      ),
    );

    final expectedBackupFolderName = AppStorage.backupFolderName;
    final verification = verify(
      () => nativeDownloadService.startDownload(
        contentId: content.id,
        sourceId: content.sourceId,
        imageUrls: captureAny(named: 'imageUrls'),
        destinationPath: tempDir.path,
        cookies: null,
        headers: null,
        title: content.title,
        url: content.url,
        coverUrl: content.coverUrl,
        language: content.language,
        startPage: 2,
        endPage: 4,
        totalPages: 5,
        enableNotifications: false,
        backupFolderName: captureAny(named: 'backupFolderName'),
        maxParallelImages: 3,
        imageTimeoutMs: 60000,
      ),
    );
    verification.called(1);

    expect(
      verification.captured[0],
      const <String>[
        'https://e-hentai.org/s/hash/3902890-2',
        'https://e-hentai.org/s/hash/3902890-3',
        'https://e-hentai.org/s/hash/3902890-4',
      ],
    );
    expect(verification.captured[1], expectedBackupFolderName);

    final metadataFile = File('${tempDir.path}/metadata.json');
    expect(await metadataFile.exists(), isTrue);

    final metadata = json.decode(await metadataFile.readAsString())
        as Map<String, dynamic>;
    expect(metadata['id'], content.id);
    expect(metadata['source'], content.sourceId);
    expect(metadata['totalImages'], 5);
  });
}
