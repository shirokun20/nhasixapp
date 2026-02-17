import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nhasixapp/data/datasources/local/local_data_source.dart';
import 'package:nhasixapp/data/models/download_status_model.dart';
import 'package:nhasixapp/data/repositories/user_data_repository_impl.dart';
import 'package:nhasixapp/domain/entities/download_status.dart';

class MockLocalDataSource extends Mock implements LocalDataSource {}

void main() {
  late UserDataRepositoryImpl repository;
  late MockLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockLocalDataSource();
    repository = UserDataRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('UserDataRepositoryImpl Pagination', () {
    const tContentId = '123';
    final tDownloadStatusModel = DownloadStatusModel(
      contentId: tContentId,
      state: DownloadState.completed,
      downloadedPages: 10,
      totalPages: 10,
      startTime: DateTime.now(),
      title: 'Test Title',
    );
    final tDownloadStatusList = [tDownloadStatusModel];

    test('getAllDownloads should pass pagination parameters to localDataSource',
        () async {
      // Arrange
      const limit = 10;
      const offset = 20;
      const state = DownloadState.completed;
      const orderBy = 'title';
      const descending = false;

      when(() => mockLocalDataSource.getAllDownloads(
            state: state,
            limit: limit,
            offset: offset,
            orderBy: orderBy,
            descending: descending,
          )).thenAnswer((_) async => tDownloadStatusList);

      // Act
      final result = await repository.getAllDownloads(
        state: state,
        limit: limit,
        offset: offset,
        orderBy: orderBy,
        descending: descending,
      );

      // Assert
      verify(() => mockLocalDataSource.getAllDownloads(
            state: state,
            limit: limit,
            offset: offset,
            orderBy: orderBy,
            descending: descending,
          )).called(1);

      expect(result.length, 1);
      expect(result.first.contentId, tContentId);
    });

    test('getDownloadsCount should return count from localDataSource',
        () async {
      // Arrange
      const tCount = 42;
      const state = DownloadState.completed;

      when(() => mockLocalDataSource.getDownloadsCount(state: state))
          .thenAnswer((_) async => tCount);

      // Act
      final result = await repository.getDownloadsCount(state: state);

      // Assert
      verify(() => mockLocalDataSource.getDownloadsCount(state: state))
          .called(1);
      expect(result, tCount);
    });

    test('searchDownloads should pass pagination parameters to localDataSource',
        () async {
      // Arrange
      const query = 'test';
      const limit = 5;
      const offset = 10;
      final tSearchResult = [
        {'id': '1', 'title': 'Test 1'}
      ];

      when(() => mockLocalDataSource.searchDownloads(
            query: query,
            limit: limit,
            offset: offset,
          )).thenAnswer((_) async => tSearchResult);

      // Act
      final result = await repository.searchDownloads(
        query: query,
        limit: limit,
        offset: offset,
      );

      // Assert
      verify(() => mockLocalDataSource.searchDownloads(
            query: query,
            limit: limit,
            offset: offset,
          )).called(1);

      expect(result, tSearchResult);
    });

    test('getSearchCount should return count from localDataSource', () async {
      // Arrange
      const query = 'test';
      const tCount = 15;

      when(() => mockLocalDataSource.getSearchCount(query: query))
          .thenAnswer((_) async => tCount);

      // Act
      final result = await repository.getSearchCount(query: query);

      // Assert
      verify(() => mockLocalDataSource.getSearchCount(query: query)).called(1);
      expect(result, tCount);
    });
  });
}
