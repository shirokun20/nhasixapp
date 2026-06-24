/// Minimal HTTP probe for source discovery.
library;

import 'dart:io';
import 'package:http/http.dart' as http;

/// Result of an HTTP probe.
class ProbeResult {
  ProbeResult({
    required this.url,
    required this.statusCode,
    required this.html,
    this.error,
  });

  final String url;
  final int statusCode;
  final String html;
  final String? error;

  bool get isSuccess => statusCode == 200 && error == null;
  bool get isBlocked => statusCode == 403 || statusCode == 503;
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
        html: response.body,
      );
    } finally {
      client.close();
    }
  } on SocketException catch (e) {
    return ProbeResult(url: url, statusCode: 0, html: '', error: 'Network: $e');
  } on HttpException catch (e) {
    return ProbeResult(url: url, statusCode: 0, html: '', error: 'HTTP: $e');
  } catch (e) {
    return ProbeResult(url: url, statusCode: 0, html: '', error: '$e');
  }
}
