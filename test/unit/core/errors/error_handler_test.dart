import 'package:flutter_test/flutter_test.dart';
import 'package:nhasixapp/core/errors/error_handler.dart';

void main() {
  group('Result', () {
    group('success', () {
      test('creates successful result', () {
        final result = Result.success(42);
        expect(result.isSuccess, true);
        expect(result.isFailure, false);
        expect(result.hasValue, true);
        expect(result.value, 42);
        expect(result.error, isNull);
      });

      test('valueOrThrow returns value on success', () {
        final result = Result.success('hello');
        expect(result.valueOrThrow, 'hello');
      });

      test('valueOr returns value on success', () {
        final result = Result.success(10);
        expect(result.valueOr(0), 10);
      });
    });

    group('failure', () {
      test('creates failed result', () {
        final result = Result<int>.failure(Exception('test error'));
        expect(result.isSuccess, false);
        expect(result.isFailure, true);
        expect(result.hasValue, false);
        expect(result.value, isNull);
        expect(result.error, isNotNull);
      });

      test('valueOrThrow throws on failure', () {
        final result = Result<int>.failure(Exception('test error'));
        expect(() => result.valueOrThrow, throwsException);
      });

      test('valueOr returns alternative on failure', () {
        final result = Result<int>.failure(Exception('test error'));
        expect(result.valueOr(99), 99);
      });
    });

    group('map', () {
      test('transforms value on success', () {
        final result = Result.success(5);
        final mapped = result.map((v) => v * 2);
        expect(mapped.isSuccess, true);
        expect(mapped.value, 10);
      });

      test('returns failure on map error', () {
        final result = Result.success(5);
        final mapped = result.map<int>((v) => throw Exception('map error'));
        expect(mapped.isFailure, true);
      });

      test('propagates failure without calling transform', () {
        final result = Result<int>.failure(Exception('original'));
        var called = false;
        final mapped = result.map((v) {
          called = true;
          return v * 2;
        });
        expect(called, false);
        expect(mapped.isFailure, true);
      });
    });

    group('fold', () {
      test('calls onSuccess for successful result', () {
        final result = Result.success(10);
        final value = result.fold(
          onSuccess: (v) => 'success: $v',
          onFailure: (e) => 'failure: $e',
        );
        expect(value, 'success: 10');
      });

      test('calls onFailure for failed result', () {
        final result = Result<int>.failure(Exception('error'));
        final value = result.fold(
          onSuccess: (v) => 'success: $v',
          onFailure: (e) => 'failure',
        );
        expect(value, 'failure');
      });
    });

    group('callbacks', () {
      test('onSuccess is called for successful result', () {
        var called = false;
        Result.success(42).onSuccess((v) => called = true);
        expect(called, true);
      });

      test('onSuccess is not called for failed result', () {
        var called = false;
        Result<int>.failure(Exception('error')).onSuccess((v) => called = true);
        expect(called, false);
      });

      test('onFailure is called for failed result', () {
        var called = false;
        Result<int>.failure(Exception('error')).onFailure((e) => called = true);
        expect(called, true);
      });

      test('onFailure is not called for successful result', () {
        var called = false;
        Result.success(42).onFailure((e) => called = true);
        expect(called, false);
      });
    });
  });

  group('ErrorHandler', () {
    group('tryAsync', () {
      test('returns success for successful operation', () async {
        final result = await ErrorHandler.tryAsync(
          () async => 42,
          logError: false,
        );
        expect(result.isSuccess, true);
        expect(result.value, 42);
      });

      test('returns failure for throwing operation', () async {
        final result = await ErrorHandler.tryAsync<int>(
          () async => throw Exception('test error'),
          logError: false,
        );
        expect(result.isFailure, true);
        expect(result.error, isNotNull);
      });
    });

    group('trySync', () {
      test('returns value for successful operation', () {
        final value = ErrorHandler.trySync(
          () => 42,
          fallback: 0,
          logError: false,
        );
        expect(value, 42);
      });

      test('returns fallback for throwing operation', () {
        final value = ErrorHandler.trySync(
          () => throw Exception('error'),
          fallback: 99,
          logError: false,
        );
        expect(value, 99);
      });
    });

    group('tryAsyncOrNull', () {
      test('returns value for successful operation', () async {
        final value = await ErrorHandler.tryAsyncOrNull(
          () async => 'success',
          logError: false,
        );
        expect(value, 'success');
      });

      test('returns null for throwing operation', () async {
        final value = await ErrorHandler.tryAsyncOrNull<String>(
          () async => throw Exception('error'),
          logError: false,
        );
        expect(value, isNull);
      });
    });
  });

  group('App Exceptions', () {
    test('NetworkException has correct message', () {
      const exception = NetworkException('Connection failed');
      expect(exception.message, 'Connection failed');
      expect(exception.toString(), 'Connection failed');
    });

    test('NetworkException with code formats correctly', () {
      const exception = NetworkException('Timeout', 'ERR_TIMEOUT');
      expect(exception.code, 'ERR_TIMEOUT');
      expect(exception.toString(), '[ERR_TIMEOUT] Timeout');
    });

    test('DataException has default message', () {
      const exception = DataException();
      expect(exception.message, 'Data error occurred');
    });

    test('FileException has default message', () {
      const exception = FileException();
      expect(exception.message, 'File operation failed');
    });

    test('PermissionException has default message', () {
      const exception = PermissionException();
      expect(exception.message, 'Permission denied');
    });

    test('NotFoundException has default message', () {
      const exception = NotFoundException();
      expect(exception.message, 'Resource not found');
    });

    test('ValidationException has default message', () {
      const exception = ValidationException();
      expect(exception.message, 'Validation failed');
    });
  });
}
