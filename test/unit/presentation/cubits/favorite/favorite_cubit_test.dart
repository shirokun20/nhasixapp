import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/domain/entities/favorite_collection.dart';
import 'package:nhasixapp/domain/repositories/user_data_repository.dart';
import 'package:nhasixapp/domain/usecases/favorites/add_to_favorites_usecase.dart';
import 'package:nhasixapp/domain/usecases/favorites/get_favorites_usecase.dart';
import 'package:nhasixapp/domain/usecases/favorites/remove_from_favorites_usecase.dart';
import 'package:nhasixapp/presentation/cubits/favorite/favorite_cubit.dart';

class MockAddToFavoritesUseCase extends Mock implements AddToFavoritesUseCase {}

class MockGetFavoritesUseCase extends Mock implements GetFavoritesUseCase {}

class MockRemoveFromFavoritesUseCase extends Mock
    implements RemoveFromFavoritesUseCase {}

class MockUserDataRepository extends Mock implements UserDataRepository {}

class MockLogger extends Mock implements Logger {}

void main() {
  late FavoriteCubit cubit;
  late MockAddToFavoritesUseCase mockAddToFavoritesUseCase;
  late MockGetFavoritesUseCase mockGetFavoritesUseCase;
  late MockRemoveFromFavoritesUseCase mockRemoveFromFavoritesUseCase;
  late MockUserDataRepository mockUserDataRepository;
  late MockLogger mockLogger;

  final tCollection = FavoriteCollection(
    id: 'collection_1',
    name: 'Favorites 1',
    createdAt: DateTime(2026, 4, 12),
    updatedAt: DateTime(2026, 4, 12),
    itemCount: 1,
  );

  final tContent = Content(
    id: '123',
    title: 'Test Title',
    coverUrl: 'https://example.com/cover.jpg',
    sourceId: 'nhentai',
    tags: [],
    artists: [],
    characters: [],
    parodies: [],
    groups: [],
    language: 'en',
    pageCount: 10,
    imageUrls: [],
    uploadDate: DateTime(2026, 4, 12),
    favorites: 0,
  );

  setUpAll(() {
    registerFallbackValue(AddToFavoritesParams.create(tContent));
    registerFallbackValue(
      const GetFavoritesParams(page: 1, limit: 20),
    );
    registerFallbackValue(
      RemoveFromFavoritesParams.fromString('123'),
    );
  });

  setUp(() {
    mockAddToFavoritesUseCase = MockAddToFavoritesUseCase();
    mockGetFavoritesUseCase = MockGetFavoritesUseCase();
    mockRemoveFromFavoritesUseCase = MockRemoveFromFavoritesUseCase();
    mockUserDataRepository = MockUserDataRepository();
    mockLogger = MockLogger();

    cubit = FavoriteCubit(
      addToFavoritesUseCase: mockAddToFavoritesUseCase,
      getFavoritesUseCase: mockGetFavoritesUseCase,
      removeFromFavoritesUseCase: mockRemoveFromFavoritesUseCase,
      userDataRepository: mockUserDataRepository,
      logger: mockLogger,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('FavoriteCubit collections', () {
    test('initial state is FavoriteInitial', () {
      expect(cubit.state, isA<FavoriteInitial>());
    });

    blocTest<FavoriteCubit, FavoriteState>(
      'loadFavorites emits loaded state with collections and active collection',
      build: () {
        when(() => mockUserDataRepository.getFavoriteCollections())
            .thenAnswer((_) async => [tCollection]);
        when(() => mockGetFavoritesUseCase(any())).thenAnswer((_) async => [
              {
                'id': '123',
                'source_id': 'nhentai',
                'title': 'Test Title',
                'cover_url': 'https://example.com/cover.jpg',
              }
            ]);
        when(() => mockUserDataRepository.getFavoritesCount(
              collectionId: 'collection_1',
            )).thenAnswer((_) async => 1);

        return cubit;
      },
      act: (cubit) => cubit.loadFavorites(
        refresh: true,
        collectionId: 'collection_1',
      ),
      expect: () => [
        isA<FavoriteLoading>(),
        isA<FavoriteLoaded>()
            .having((s) => s.collections.length, 'collections length', 1)
            .having((s) => s.favorites.length, 'favorites length', 1)
            .having((s) => s.activeCollectionId, 'activeCollectionId',
                'collection_1')
            .having((s) => s.totalCount, 'totalCount', 1),
      ],
      verify: (_) {
        verify(() => mockUserDataRepository.getFavoriteCollections()).called(1);
        verify(() => mockUserDataRepository.getFavoritesCount(
              collectionId: 'collection_1',
            )).called(1);
      },
    );

    blocTest<FavoriteCubit, FavoriteState>(
      'createCollection refreshes current list after repository succeeds',
      build: () {
        when(() => mockUserDataRepository.createFavoriteCollection(
              name: 'Favorites 2',
              collectionId: any(named: 'collectionId'),
            )).thenAnswer((_) async => FavoriteCollection(
              id: 'collection_2',
              name: 'Favorites 2',
              createdAt: DateTime(2026, 4, 12),
              updatedAt: DateTime(2026, 4, 12),
            ));
        when(() => mockUserDataRepository.getFavoriteCollections())
            .thenAnswer((_) async => [
                  tCollection,
                  FavoriteCollection(
                    id: 'collection_2',
                    name: 'Favorites 2',
                    createdAt: DateTime(2026, 4, 12),
                    updatedAt: DateTime(2026, 4, 12),
                  ),
                ]);
        when(() => mockGetFavoritesUseCase(any())).thenAnswer((_) async => []);
        when(() => mockUserDataRepository.getFavoritesCount(
              collectionId: any(named: 'collectionId'),
            )).thenAnswer((_) async => 0);

        return cubit;
      },
      act: (cubit) async {
        await cubit.createCollection('Favorites 2');
      },
      expect: () => [
        isA<FavoriteLoading>(),
        isA<FavoriteLoaded>().having(
          (s) => s.collections.length,
          'collections length',
          2,
        ),
      ],
      verify: (_) {
        verify(() => mockUserDataRepository.createFavoriteCollection(
              name: 'Favorites 2',
              collectionId: any(named: 'collectionId'),
            )).called(1);
      },
    );

    test('exportFavorites includes collections and memberships', () async {
      when(() => mockUserDataRepository.getAllFavoritesForExport())
          .thenAnswer((_) async => [
                {
                  'id': '123',
                  'source_id': 'nhentai',
                  'title': 'Test Title',
                  'cover_url': 'https://example.com/cover.jpg',
                }
              ]);
      when(() => mockUserDataRepository.getFavoriteCollectionsForExport())
          .thenAnswer((_) async => [tCollection]);
      when(() => mockUserDataRepository
              .getFavoriteCollectionMembershipsForExport())
          .thenAnswer((_) async => [
                {
                  'collection_id': 'collection_1',
                  'favorite_id': '123',
                  'source_id': 'nhentai',
                }
              ]);

      final result = await cubit.exportFavorites();

      expect(result['version'], '2.0');
      expect((result['favorites'] as List), hasLength(1));
      expect((result['collections'] as List), hasLength(1));
      expect((result['collection_items'] as List), hasLength(1));
    });
  });
}
