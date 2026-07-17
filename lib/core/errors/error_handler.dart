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
