/// Minimal HTTP probe for source discovery.
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Content type detected.
enum ProbeContentType { html, json, unknown }

/// Result of an HTTP probe.
class ProbeResult {
  ProbeResult({
    required this.url,
    required this.statusCode,
    required this.body,
    this.contentType = ProbeContentType.unknown,
    this.error,
  });

  final String url;
  final int statusCode;
  final String body;
  final ProbeContentType contentType;
  final String? error;

  bool get isSuccess => statusCode == 200 && error == null;
  bool get isBlocked => statusCode == 403 || statusCode == 503;

  /// Parse body as JSON when applicable.
  dynamic get jsonBody {
    if (contentType == ProbeContentType.json) {
      try {
        return jsonDecode(body);
      } catch (_) {}
    }
    return null;
  }
}

/// Infer content type from response headers and body.
ProbeContentType _inferContentType(int statusCode, Map<String, String> headers, String body) {
  if (statusCode != 200) return ProbeContentType.unknown;
  final ct = headers['content-type']?.toLowerCase() ?? '';
  if (ct.contains('json') || ct.contains('+json')) return ProbeContentType.json;
  if (ct.contains('html')) return ProbeContentType.html;
  // Sniff body
  final trimmed = body.trim();
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    try {
      jsonDecode(trimmed);
      return ProbeContentType.json;
    } catch (_) {}
  }
  if (trimmed.startsWith('<!DOCTYPE') || trimmed.startsWith('<html')) {
    return ProbeContentType.html;
  }
  return ProbeContentType.unknown;
}

/// Probe a URL with browser-like headers.
Future<ProbeResult> probeUrl(String url) async {
  try {
    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36'
              ' (KHTML, like Gecko) Chrome/120.0.6099.230 Mobile Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 15));

      return ProbeResult(
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        contentType: _inferContentType(response.statusCode, response.headers, response.body),
      );
    } finally {
      client.close();
    }
  } on SocketException catch (e) {
    return ProbeResult(url: url, statusCode: 0, body: '', error: 'Network: $e');
  } on HttpException catch (e) {
    return ProbeResult(url: url, statusCode: 0, body: '', error: 'HTTP: $e');
  } catch (e) {
    return ProbeResult(url: url, statusCode: 0, body: '', error: '$e');
  }
}
