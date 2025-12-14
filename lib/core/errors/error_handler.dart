import 'package:logger/logger.dart';

/// Standard error handling utilities for consistent error management
/// across the application.
///
/// Usage patterns:
/// ```dart
/// // For async operations that should not throw
/// final result = await ErrorHandler.tryAsync(
///   () => someAsyncOperation(),
///   operationName: 'fetchData',
/// );
/// if (result.hasValue) { ... }
///
/// // For sync operations with fallback
/// final value = ErrorHandler.trySync(
///   () => riskyOperation(),
///   fallback: defaultValue,
/// );
/// ```
class ErrorHandler {
  ErrorHandler._();

  static final Logger _logger = Logger();

  /// Execute an async operation with standardized error handling
  ///
  /// Returns a [Result] that can be checked for success/failure
  static Future<Result<T>> tryAsync<T>(
    Future<T> Function() operation, {
    String? operationName,
    bool logError = true,
    bool logStackTrace = false,
  }) async {
    try {
      final value = await operation();
      return Result.success(value);
    } catch (e, stackTrace) {
      if (logError) {
        final name = operationName ?? 'operation';
        if (logStackTrace) {
          _logger.e('Error in $name', error: e, stackTrace: stackTrace);
        } else {
          _logger.e('Error in $name: $e');
        }
      }
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Execute a sync operation with fallback value on error
  static T trySync<T>(
    T Function() operation, {
    required T fallback,
    String? operationName,
    bool logError = true,
  }) {
    try {
      return operation();
    } catch (e) {
      if (logError) {
        final name = operationName ?? 'operation';
        _logger.e('Error in $name: $e');
      }
      return fallback;
    }
  }

  /// Execute an async operation, returning null on error
  static Future<T?> tryAsyncOrNull<T>(
    Future<T> Function() operation, {
    String? operationName,
    bool logError = true,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (logError) {
        final name = operationName ?? 'operation';
        _logger.e('Error in $name: $e');
      }
      return null;
    }
  }

  /// Log error with consistent formatting
  static void logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? context,
  }) {
    final contextPrefix = context != null ? '[$context] ' : '';
    _logger.e('$contextPrefix$message', error: error, stackTrace: stackTrace);
  }

  /// Log warning with consistent formatting
  static void logWarning(String message, {String? context}) {
    final contextPrefix = context != null ? '[$context] ' : '';
    _logger.w('$contextPrefix$message');
  }
}

/// Result class for operations that can fail
///
/// Provides a type-safe way to handle success/failure cases
class Result<T> {
  const Result._({
    this.value,
    this.error,
    required this.isSuccess,
  });

  final T? value;
  final Exception? error;
  final bool isSuccess;

  bool get isFailure => !isSuccess;
  bool get hasValue => isSuccess && value != null;

  factory Result.success(T value) {
    return Result._(value: value, isSuccess: true);
  }

  factory Result.failure(Exception error) {
    return Result._(error: error, isSuccess: false);
  }

  /// Get value or throw if failure
  T get valueOrThrow {
    if (isFailure) {
      throw error ?? Exception('Unknown error');
    }
    return value as T;
  }

  /// Get value or return alternative
  T valueOr(T alternative) {
    return isSuccess ? value as T : alternative;
  }

  /// Transform value if success
  Result<R> map<R>(R Function(T value) transform) {
    if (isSuccess) {
      try {
        return Result.success(transform(value as T));
      } catch (e) {
        return Result.failure(e is Exception ? e : Exception(e.toString()));
      }
    }
    return Result.failure(error!);
  }

  /// Handle both success and failure cases
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Exception error) onFailure,
  }) {
    if (isSuccess) {
      return onSuccess(value as T);
    }
    return onFailure(error!);
  }

  /// Execute callback on success
  Result<T> onSuccess(void Function(T value) callback) {
    if (isSuccess) {
      callback(value as T);
    }
    return this;
  }

  /// Execute callback on failure
  Result<T> onFailure(void Function(Exception error) callback) {
    if (isFailure) {
      callback(error!);
    }
    return this;
  }
}

/// Common application exceptions
abstract class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Network error occurred',
    String? code,
  ]) : super(code: code);
}

/// Data/Cache related exceptions
class DataException extends AppException {
  const DataException([
    super.message = 'Data error occurred',
    String? code,
  ]) : super(code: code);
}

/// File system related exceptions
class FileException extends AppException {
  const FileException([
    super.message = 'File operation failed',
    String? code,
  ]) : super(code: code);
}

/// Permission related exceptions
class PermissionException extends AppException {
  const PermissionException([
    super.message = 'Permission denied',
    String? code,
  ]) : super(code: code);
}

/// Content not found exceptions
class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'Resource not found',
    String? code,
  ]) : super(code: code);
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException([
    super.message = 'Validation failed',
    String? code,
  ]) : super(code: code);
}
