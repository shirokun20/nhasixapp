/// Utilities to redact secrets from header maps, URLs, and JSON payloads
/// before they are written into a [ValidationReport],
/// [ValidationDiagnostic], or persisted compatibility log.
///
/// All redaction is conservative: when in doubt, redact. Redaction is
/// length-preserving (replaces value with `***`) so consumers can still
/// tell that a value was present.
///
/// This class is intentionally not configurable; the set of sensitive
/// names is treated as a runtime constant so different reports always
/// redact the same fields.
class SecretRedactor {
  SecretRedactor._();

  /// Placeholder used in place of a redacted value.
  static const String placeholder = '***';

  /// Header names whose values are always redacted. Comparison is case
  /// insensitive.
  static const Set<String> _sensitiveHeaderNames = <String>{
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'x-auth-token',
    'x-csrf-token',
    'x-xsrf-token',
    'x-session-id',
    'x-session-token',
    'x-access-token',
    'x-refresh-token',
  };

  /// URL query parameter names whose values are always redacted. Comparison
  /// is case insensitive.
  static const Set<String> _sensitiveQueryKeys = <String>{
    'token',
    'access_token',
    'refresh_token',
    'api_key',
    'apikey',
    'apitoken',
    'auth',
    'authorization',
    'sessionid',
    'session_id',
    'sid',
    'signature',
    'sig',
    'sign',
    'key',
    'secret',
    'password',
    'pwd',
    'nonce',
    'csrf',
    'xsrf',
  };

  /// JSON keys whose values are always redacted at any depth. Comparison
  /// is case insensitive.
  static const Set<String> _sensitiveJsonKeys = <String>{
    'cookie',
    'cookies',
    'setcookie',
    'authorization',
    'token',
    'accesstoken',
    'refreshtoken',
    'apikey',
    'apitoken',
    'sessionid',
    'sid',
    'password',
    'pwd',
    'secret',
    'nonce',
    'csrf',
    'xsrf',
    'signature',
    'sig',
  };

  /// Returns a copy of [headers] with sensitive values replaced by
  /// [placeholder]. Empty values are kept empty (an empty string is not a
  /// secret).
  static Map<String, String> redactHeaders(Map<String, String> headers) {
    final Map<String, String> out = <String, String>{};
    headers.forEach((String name, String value) {
      if (value.isEmpty) {
        out[name] = value;
        return;
      }
      if (_sensitiveHeaderNames.contains(name.toLowerCase())) {
        out[name] = placeholder;
      } else {
        out[name] = value;
      }
    });
    return out;
  }

  /// Returns a copy of [url] with sensitive query parameter values replaced
  /// by [placeholder]. Returns the original string unchanged when [url] is
  /// not a valid URI.
  static String redactUrl(String url) {
    if (url.isEmpty) return url;
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.queryParameters.isEmpty) return url;

    final Map<String, String> redactedParams = <String, String>{};
    uri.queryParameters.forEach((String key, String value) {
      if (_sensitiveQueryKeys.contains(key.toLowerCase()) && value.isNotEmpty) {
        redactedParams[key] = placeholder;
      } else {
        redactedParams[key] = value;
      }
    });
    return uri.replace(queryParameters: redactedParams).toString();
  }

  /// Returns a deep-redacted copy of [data].
  ///
  /// - Map keys matching [_sensitiveJsonKeys] have their values replaced
  ///   with [placeholder] at any depth.
  /// - String values that look like URLs are passed through [redactUrl].
  /// - Nested maps/lists are walked recursively.
  /// - Non-string scalars are preserved.
  static Map<String, Object?> redactJson(Map<String, Object?> data) {
    return _redactJsonMap(data);
  }

  static Map<String, Object?> _redactJsonMap(Map<String, Object?> data) {
    final Map<String, Object?> out = <String, Object?>{};
    data.forEach((String key, Object? value) {
      final bool isSensitive = _sensitiveJsonKeys.contains(
        _normalizeKey(key),
      );
      out[key] =
          isSensitive ? _redactSensitiveValue(value) : _redactJsonValue(value);
    });
    return out;
  }

  static Object? _redactJsonValue(Object? value) {
    if (value is Map) {
      return _redactJsonMap(value.map<String, Object?>(
        (Object? k, Object? v) => MapEntry<String, Object?>(
          k.toString(),
          v,
        ),
      ));
    }
    if (value is List) {
      return value
          .map<Object?>((Object? element) => _redactJsonValue(element))
          .toList(growable: false);
    }
    if (value is String) {
      // Try to redact URL query parameters even when the surrounding key
      // is not sensitive.
      if (_looksLikeUrl(value)) return redactUrl(value);
      return value;
    }
    return value;
  }

  static Object? _redactSensitiveValue(Object? value) {
    if (value == null) return null;
    if (value is Map) {
      // Sensitive maps still get walked so each leaf becomes placeholder.
      final Map<String, Object?> nested = value.map<String, Object?>(
          (Object? k, Object? v) => MapEntry<String, Object?>(k.toString(), v));
      return nested.map<String, Object?>(
        (String k, Object? v) =>
            MapEntry<String, Object?>(k, _redactSensitiveValue(v)),
      );
    }
    if (value is List) {
      return value
          .map<Object?>((Object? e) => _redactSensitiveValue(e))
          .toList(growable: false);
    }
    if (value is String) {
      return value.isEmpty ? value : placeholder;
    }
    // Numbers and bools that arrived under a sensitive key are still
    // censored to avoid leaking, e.g., numeric tokens.
    return placeholder;
  }

  static String _normalizeKey(String key) {
    final String lower = key.toLowerCase();
    return lower.replaceAll('_', '').replaceAll('-', '').replaceAll(' ', '');
  }

  static bool _looksLikeUrl(String value) {
    if (value.length < 8) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }
}
