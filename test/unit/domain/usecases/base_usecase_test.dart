import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/domain/usecases/base_usecase.dart';

void main() {
  group('UseCaseResult', () {
    group('success', () {
      test('creates successful result with data', () {
        final result = UseCaseResult.success('test data');
        expect(result.isSuccess, true);
        expect(result.isFailure, false);
        expect(result.data, 'test data');
        expect(result.error, isNull);
      });

      test('dataOrThrow returns data on success', () {
        final result = UseCaseResult.success(42);
        expect(result.dataOrThrow, 42);
      });

      test('getDataOrElse returns data on success', () {
        final result = UseCaseResult.success(42);
        expect(result.getDataOrElse(0), 42);
      });
    });

    group('failure', () {
      test('creates failure result with error', () {
        final result = UseCaseResult<int>.failure(
          Exception('test error'),
          'Custom message',
        );
        expect(result.isSuccess, false);
        expect(result.isFailure, true);
        expect(result.data, isNull);
        expect(result.error, isNotNull);
        expect(result.message, 'Custom message');
      });

      test('dataOrThrow throws on failure', () {
        final result = UseCaseResult<int>.failure(Exception('error'));
        expect(() => result.dataOrThrow, throwsException);
      });

      test('getDataOrElse returns default on failure', () {
        final result = UseCaseResult<int>.failure(Exception('error'));
        expect(result.getDataOrElse(99), 99);
      });
    });

    group('map', () {
      test('transforms data on success', () {
        final result = UseCaseResult.success(5);
        final mapped = result.map((data) => data * 2);
        expect(mapped.isSuccess, true);
        expect(mapped.data, 10);
      });

      test('returns failure when transform throws', () {
        final result = UseCaseResult.success(5);
        final mapped =
            result.map<int>((data) => throw Exception('transform error'));
        expect(mapped.isFailure, true);
      });

      test('propagates failure without transform', () {
        final result = UseCaseResult<int>.failure(Exception('original'));
        final mapped = result.map((data) => data * 2);
        expect(mapped.isFailure, true);
      });
    });

    group('fold', () {
      test('calls onSuccess for successful result', () {
        final result = UseCaseResult.success(10);
        final value = result.fold(
          (error, message) => 'failure',
          (data) => 'success: $data',
        );
        expect(value, 'success: 10');
      });

      test('calls onFailure for failed result', () {
        final result = UseCaseResult<int>.failure(
          Exception('error'),
          'Error message',
        );
        final value = result.fold(
          (error, message) => 'failure: $message',
          (data) => 'success: $data',
        );
        expect(value, 'failure: Error message');
      });
    });
  });

  group('PaginatedResult', () {
    test('creates result with items', () {
      const result = PaginatedResult<int>(
        items: [1, 2, 3],
        currentPage: 1,
        totalPages: 5,
        totalCount: 50,
        hasNext: true,
        hasPrevious: false,
      );

      expect(result.items, [1, 2, 3]);
      expect(result.currentPage, 1);
      expect(result.totalPages, 5);
      expect(result.totalCount, 50);
      expect(result.hasNext, true);
      expect(result.hasPrevious, false);
      expect(result.count, 3);
      expect(result.isEmpty, false);
      expect(result.isNotEmpty, true);
    });

    test('empty creates empty result', () {
      final result = PaginatedResult<int>.empty();
      expect(result.items, isEmpty);
      expect(result.currentPage, 1);
      expect(result.totalPages, 0);
      expect(result.totalCount, 0);
      expect(result.isEmpty, true);
    });

    test('single creates single-page result', () {
      final result = PaginatedResult<String>.single(['a', 'b', 'c']);
      expect(result.items, ['a', 'b', 'c']);
      expect(result.currentPage, 1);
      expect(result.totalPages, 1);
      expect(result.totalCount, 3);
      expect(result.hasNext, false);
    });

    test('map transforms items', () {
      const result = PaginatedResult<int>(
        items: [1, 2, 3],
        currentPage: 1,
        totalPages: 1,
        totalCount: 3,
      );

      final mapped = result.map((item) => item.toString());
      expect(mapped.items, ['1', '2', '3']);
      expect(mapped.currentPage, 1);
      expect(mapped.totalCount, 3);
    });
  });

  group('NoParams', () {
    test('NoParams are equal', () {
      const params1 = NoParams();
      const params2 = NoParams();
      expect(params1, equals(params2));
    });
  });

  group('UseCaseExceptions', () {
    test('NetworkException has message', () {
      const exception = NetworkException('Connection failed');
      expect(exception.message, 'Connection failed');
      expect(exception.toString(), 'Connection failed');
    });

    test('NetworkException has default message', () {
      const exception = NetworkException();
      expect(exception.message, 'Network error occurred');
    });

    test('ServerException has default message', () {
      const exception = ServerException();
      expect(exception.message, 'Server error occurred');
    });

    test('CacheException has default message', () {
      const exception = CacheException();
      expect(exception.message, 'Cache error occurred');
    });

    test('ValidationException has default message', () {
      const exception = ValidationException();
      expect(exception.message, 'Validation error occurred');
    });

    test('NotFoundException has default message', () {
      const exception = NotFoundException();
      expect(exception.message, 'Resource not found');
    });

    test('UnauthorizedException has default message', () {
      const exception = UnauthorizedException();
      expect(exception.message, 'Unauthorized access');
    });

    test('TimeoutException has default message', () {
      const exception = TimeoutException();
      expect(exception.message, 'Operation timed out');
    });
  });
}
