/// Base exception for remote data source errors
abstract class RemoteDataSourceException implements Exception {
  const RemoteDataSourceException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() =>
      'RemoteDataSourceException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends RemoteDataSourceException {
  const NetworkException(super.message, [super.code]);
}

/// Server error exceptions (5xx status codes)
class ServerException extends RemoteDataSourceException {
  const ServerException(super.message, [super.code]);
}

/// Cloudflare protection exceptions
class CloudflareException extends RemoteDataSourceException {
  const CloudflareException(super.message, [super.code]);
}

/// HTML parsing exceptions
class ParseException extends RemoteDataSourceException {
  const ParseException(super.message, [super.code]);
}

/// Rate limiting exceptions
class RateLimitException extends RemoteDataSourceException {
  const RateLimitException(super.message, [super.code]);
}

/// Content not found exceptions
class ContentNotFoundException extends RemoteDataSourceException {
  const ContentNotFoundException(super.message, [super.code]);
}

/// Timeout exceptions
class TimeoutException extends RemoteDataSourceException {
  const TimeoutException(super.message, [super.code]);
}

/// Anti-detection failure exceptions
class AntiDetectionException extends RemoteDataSourceException {
  const AntiDetectionException(super.message, [super.code]);
}
