import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart' as core;
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/core/config/remote_config_service.dart';
import 'package:nhasixapp/data/datasources/remote/remote_data_source.dart';
import 'package:nhasixapp/data/repositories/content_repository_impl.dart';
import 'package:nhasixapp/domain/entities/entities.dart';
import 'package:nhasixapp/domain/value_objects/value_objects.dart';
import 'package:nhasixapp/services/cache/cache_manager.dart' as multi_cache;
import 'package:nhasixapp/services/detail_cache_service.dart';
import 'package:nhasixapp/services/request_deduplication_service.dart';

class MockRemoteConfigService extends Mock implements RemoteConfigService {}

class MockRemoteDataSource extends Mock implements RemoteDataSource {}

class MockDetailCacheService extends Mock implements DetailCacheService {}

class MockContentCacheManager extends Mock
    implements multi_cache.CacheManager<Map<String, dynamic>> {}

class MockTagCacheManager extends Mock
    implements multi_cache.CacheManager<List<Tag>> {}

class MockContentSource extends Mock implements core.ContentSource {}

void main() {
  late core.ContentSourceRegistry registry;
  late MockRemoteConfigService remoteConfigService;
  late MockRemoteDataSource remoteDataSource;
  late MockDetailCacheService detailCacheService;
  late MockContentCacheManager contentCacheManager;
  late MockTagCacheManager tagCacheManager;
  late MockContentSource source;
  late ContentRepositoryImpl repository;

  const sourceId = 'komiktap';
  const contentId = 'you-wont-break-me';

  final staleCachedContent = Content(
    id: contentId,
    sourceId: sourceId,
    title: "You Won't Break Me",
    coverUrl: 'https://cdn.example.com/cover.jpg',
    tags: const [],
    artists: const [],
    characters: const [],
    parodies: const [],
    groups: const [],
    language: 'id',
    pageCount: 18,
    imageUrls: const ['https://cdn.example.com/cover.jpg'],
    uploadDate: DateTime(2026, 5, 19),
    chapters: null,
  );

  final freshContent = Content(
    id: contentId,
    sourceId: sourceId,
    title: "You Won't Break Me",
    coverUrl: 'https://cdn.example.com/cover.jpg',
    tags: const [],
    artists: const [],
    characters: const [],
    parodies: const [],
    groups: const [],
    language: 'id',
    pageCount: 2,
    imageUrls: const [],
    uploadDate: DateTime(2026, 5, 19),
    chapters: [
      const core.Chapter(
        id: 'you-wont-break-me-chapter-37',
        title: 'Chapter 37',
        url: 'https://komiktap.info/you-wont-break-me-chapter-37/',
      ),
      const core.Chapter(
        id: 'you-wont-break-me-chapter-36',
        title: 'Chapter 36',
        url: 'https://komiktap.info/you-wont-break-me-chapter-36/',
      ),
    ],
  );

  setUp(() {
    registry = core.ContentSourceRegistry();
    remoteConfigService = MockRemoteConfigService();
    remoteDataSource = MockRemoteDataSource();
    detailCacheService = MockDetailCacheService();
    contentCacheManager = MockContentCacheManager();
    tagCacheManager = MockTagCacheManager();
    source = MockContentSource();

    when(() => source.id).thenReturn(sourceId);
    when(() => source.displayName).thenReturn('KomikTap');
    registry.register(source);

    when(() => remoteConfigService.isFeatureEnabled(sourceId, any()))
        .thenReturn(true);

    when(() => contentCacheManager.get(any())).thenAnswer((_) async => null);
    when(() => contentCacheManager.set(any(), any(), ttl: any(named: 'ttl')))
        .thenAnswer((_) async {});
    when(() => detailCacheService.cacheDetail(freshContent))
        .thenAnswer((_) async {});

    repository = ContentRepositoryImpl(
      contentSourceRegistry: registry,
      remoteConfigService: remoteConfigService,
      remoteDataSource: remoteDataSource,
      detailCacheService: detailCacheService,
      requestDeduplicationService: RequestDeduplicationService(),
      contentCacheManager: contentCacheManager,
      tagCacheManager: tagCacheManager,
    );
  });

  test(
      'getContentDetail bypasses stale chapter cache when chapter feature is enabled',
      () async {
    when(() => detailCacheService.getCachedDetail(contentId))
        .thenAnswer((_) async => staleCachedContent);
    when(() => source.getDetail(contentId))
        .thenAnswer((_) async => freshContent);

    final result =
        await repository.getContentDetail(ContentId.fromString(contentId));

    expect(result.chapters, isNotNull);
    expect(result.chapters, hasLength(2));
    expect(result.chapters!.first.id, 'you-wont-break-me-chapter-37');
    verify(() => source.getDetail(contentId)).called(1);
    verify(() => detailCacheService.getCachedDetail(contentId)).called(1);
  });
}
