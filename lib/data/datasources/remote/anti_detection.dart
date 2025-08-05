import 'dart:math';

import 'package:logger/logger.dart';

/// Anti-detection measures for web scraping
class AntiDetection {
  AntiDetection({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;
  final Random _random = Random();

  DateTime? _lastRequestTime;
  int _requestCount = 0;
  String? _currentUserAgent;

  // User agent rotation pool
  static const List<String> _userAgents = [
    // Chrome on Windows
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',

    // Chrome on macOS
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',

    // Firefox on Windows
    'Gecko/20100101 Firefox/120.0',
    'Gecko/20100101 Firefox/119.0',

    // Firefox on macOS
    'Gecko/20100101 Firefox/120.0',

    // Safari on macOS
    'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
    'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',

    // Edge on Windows
    'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0',
  ];

  // Common accept headers
  static const List<String> _acceptHeaders = [
    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
  ];

  // Accept-Language headers
  static const List<String> _acceptLanguageHeaders = [
    'en-US,en;q=0.9',
    'en-US,en;q=0.9,ja;q=0.8',
    'en-US,en;q=0.8,ja;q=0.7',
    'en,ja;q=0.9',
    'ja,en-US;q=0.9,en;q=0.8',
  ];

  /// Initialize anti-detection measures
  Future<void> initialize() async {
    try {
      _logger.i('Initializing anti-detection measures...');

      // Set initial user agent
      _currentUserAgent = _getRandomUserAgent();

      _logger.i('Anti-detection measures initialized');
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize anti-detection',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Apply random delay between requests
  Future<void> applyRandomDelay() async {
    final now = DateTime.now();

    if (_lastRequestTime != null) {
      final timeSinceLastRequest = now.difference(_lastRequestTime!);
      final minDelay = _calculateMinDelay();

      if (timeSinceLastRequest < minDelay) {
        final additionalDelay = minDelay - timeSinceLastRequest;
        final jitter = Duration(milliseconds: _random.nextInt(500));
        final totalDelay = additionalDelay + jitter;

        _logger.d('Applying delay: ${totalDelay.inMilliseconds}ms');
        await Future.delayed(totalDelay);
      }
    }

    _lastRequestTime = now;
    _requestCount++;
  }

  /// Get random headers for request
  Map<String, String> getRandomHeaders() {
    // Rotate user agent occasionally

    if (_requestCount % 10 == 0 || _currentUserAgent == null) {
      _currentUserAgent = _getRandomUserAgent();
    }

    final headers = <String, String>{
      'User-Agent': _currentUserAgent!,
      'Accept': _getRandomAcceptHeader(),
      'Accept-Language': _getRandomAcceptLanguageHeader(),
      'Accept-Encoding': 'gzip, deflate', // ← safer untuk decoding
      'DNT': '1',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      'Cache-Control': 'max-age=0',
      'Referer': 'https://nhentai.net/', // ← selalu sertakan referer!
    };

    // Randomly add some optional headers
    if (_random.nextBool()) {
      headers['Sec-CH-UA'] = _generateSecChUa();
    }

    if (_random.nextBool()) {
      headers['Sec-CH-UA-Mobile'] = '?0';
    }

    if (_random.nextBool()) {
      headers['Sec-CH-UA-Platform'] = _getRandomPlatform();
    }

    // Add referer occasionally (simulate browsing behavior)
    // if (_requestCount > 1 && _random.nextDouble() < 0.3) {
    //   headers['Referer'] = 'https://nhentai.net/';
    // }

    return headers;
  }

  /// Calculate minimum delay based on request frequency
  Duration _calculateMinDelay() {
    // Increase delay as request count increases to avoid rate limiting
    final baseDelay = 1000; // 1 second base
    final additionalDelay =
        (_requestCount ~/ 10) * 500; // +500ms per 10 requests
    final maxDelay = 5000; // Max 5 seconds

    final totalDelay = (baseDelay + additionalDelay).clamp(baseDelay, maxDelay);
    return Duration(milliseconds: totalDelay);
  }

  /// Get random user agent
  String _getRandomUserAgent() {
    return _userAgents[_random.nextInt(_userAgents.length)];
  }

  /// Get random accept header
  String _getRandomAcceptHeader() {
    return _acceptHeaders[_random.nextInt(_acceptHeaders.length)];
  }

  /// Get random accept-language header
  String _getRandomAcceptLanguageHeader() {
    return _acceptLanguageHeaders[
        _random.nextInt(_acceptLanguageHeaders.length)];
  }


  /// Generate Sec-CH-UA header
  String _generateSecChUa() {
    final chromeVersion = 120 - _random.nextInt(3); // Recent Chrome versions
    return '"Not_A Brand";v="8", "Chromium";v="$chromeVersion", "Google Chrome";v="$chromeVersion"';
  }

  /// Get random platform for Sec-CH-UA-Platform
  String _getRandomPlatform() {
    final platforms = ['"Windows"', '"macOS"', '"Linux"'];
    return platforms[_random.nextInt(platforms.length)];
  }

  /// Simulate human-like browsing patterns
  Future<void> simulateHumanBehavior() async {
    // Occasionally pause longer (simulate reading)
    if (_random.nextDouble() < 0.1) {
      final readingDelay = Duration(
        milliseconds: 3000 + _random.nextInt(7000), // 3-10 seconds
      );
      _logger.d('Simulating reading behavior: ${readingDelay.inSeconds}s');
      await Future.delayed(readingDelay);
    }

    // Vary request patterns
    if (_requestCount % 20 == 0) {
      final breakDelay = Duration(
        milliseconds: 10000 + _random.nextInt(20000), // 10-30 seconds
      );
      _logger.d('Taking a break: ${breakDelay.inSeconds}s');
      await Future.delayed(breakDelay);
    }
  }

  /// Check if we should throttle requests
  bool shouldThrottleRequests() {
    // Throttle if making too many requests too quickly
    const maxRequestsPerMinute = 30;
    const timeWindow = Duration(minutes: 1);

    if (_lastRequestTime != null) {
      final timeSinceStart = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceStart < timeWindow && _requestCount > maxRequestsPerMinute) {
        return true;
      }
    }

    return false;
  }

  /// Reset request counters (call periodically)
  void resetCounters() {
    _requestCount = 0;
    _lastRequestTime = null;
    _logger.d('Reset anti-detection counters');
  }

  /// Get current request statistics
  Map<String, dynamic> getStatistics() {
    return {
      'requestCount': _requestCount,
      'lastRequestTime': _lastRequestTime?.toIso8601String(),
      'currentUserAgent': _currentUserAgent,
      'shouldThrottle': shouldThrottleRequests(),
    };
  }

  /// Dispose resources
  void dispose() {
    _logger.i('Anti-detection disposed');
  }
}
