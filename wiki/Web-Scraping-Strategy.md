# 🌐 Web Scraping Strategy

This document outlines the comprehensive web scraping strategy used in NhentaiApp to extract content from nhentai.net while maintaining reliability and avoiding detection.

## 📋 Table of Contents
- [Scraping Architecture](#scraping-architecture)
- [Anti-Detection Measures](#anti-detection-measures)
- [HTML Parsing Strategy](#html-parsing-strategy)
- [Cloudflare Bypass](#cloudflare-bypass)
- [Error Handling](#error-handling)
- [Performance Optimization](#performance-optimization)

---

## 🏗️ Scraping Architecture

### **Overall Strategy**
The app uses a multi-layered approach to web scraping:
1. **Cloudflare Bypass**: WebView-based bypass for initial access
2. **HTML Parsing**: Direct HTML parsing using CSS selectors
3. **Anti-Detection**: Multiple techniques to avoid blocking
4. **Caching**: Intelligent caching to reduce server load
5. **Fallback**: Graceful degradation when scraping fails

### **Data Flow**
```
User Request → RemoteDataSource → Anti-Detection → HTTP Request → HTML Parser → Data Models → Cache → UI
```

### **Implementation Structure**
```
lib/data/datasources/remote/
├── remote_data_source.dart          # Main scraping interface
├── anti_detection.dart              # Anti-detection utilities
├── html_parser.dart                 # HTML parsing logic
├── cloudflare_bypass.dart           # Cloudflare bypass implementation
└── scraping_utils.dart              # Utility functions
```

---

## 🛡️ Anti-Detection Measures

### **1. User-Agent Rotation**
```dart
class AntiDetection {
  static final List<String> _userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0',
  ];

  static String getRandomUserAgent() {
    return _userAgents[Random().nextInt(_userAgents.length)];
  }

  static Map<String, String> getHeaders() {
    return {
      'User-Agent': getRandomUserAgent(),
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate, br',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Cache-Control': 'max-age=0',
    };
  }
}
```

### **2. Request Timing & Rate Limiting**
```dart
class RequestThrottler {
  static const Duration _minDelay = Duration(milliseconds: 1000);
  static const Duration _maxDelay = Duration(milliseconds: 3000);
  static DateTime? _lastRequest;

  static Future<void> throttle() async {
    if (_lastRequest != null) {
      final elapsed = DateTime.now().difference(_lastRequest!);
      final randomDelay = Duration(
        milliseconds: _minDelay.inMilliseconds + 
                     Random().nextInt(_maxDelay.inMilliseconds - _minDelay.inMilliseconds),
      );

      if (elapsed < randomDelay) {
        await Future.delayed(randomDelay - elapsed);
      }
    }
    _lastRequest = DateTime.now();
  }
}
```

### **3. Session Management**
```dart
class SessionManager {
  static final CookieJar _cookieJar = CookieJar();
  static final Dio _dio = Dio();

  static void initialize() {
    _dio.interceptors.add(CookieManager(_cookieJar));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll(AntiDetection.getHeaders());
          handler.next(options);
        },
        onError: (error, handler) {
          _handleError(error);
          handler.next(error);
        },
      ),
    );
  }

  static Future<Response> get(String url) async {
    await RequestThrottler.throttle();
    return await _dio.get(url);
  }
}
```

### **4. IP Rotation & Proxy Support**
```dart
class ProxyManager {
  static List<String> _proxyList = [];
  static int _currentProxyIndex = 0;

  static void setProxyList(List<String> proxies) {
    _proxyList = proxies;
  }

  static String? getCurrentProxy() {
    if (_proxyList.isEmpty) return null;
    return _proxyList[_currentProxyIndex % _proxyList.length];
  }

  static void rotateProxy() {
    if (_proxyList.isNotEmpty) {
      _currentProxyIndex = (_currentProxyIndex + 1) % _proxyList.length;
    }
  }

  static void configureProxy(Dio dio) {
    final proxy = getCurrentProxy();
    if (proxy != null) {
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
        client.findProxy = (uri) => 'PROXY $proxy';
        return client;
      };
    }
  }
}
```

---

## 📄 HTML Parsing Strategy

### **1. CSS Selector Patterns**
```dart
class NhentaiSelectors {
  // Main page content list
  static const String CONTENT_GALLERY = '.gallery';
  static const String CONTENT_TITLE = '.caption';
  static const String CONTENT_COVER = '.cover img';
  static const String CONTENT_LINK = 'a';

  // Detail page selectors
  static const String DETAIL_TITLE = '#info h1, #info h2';
  static const String DETAIL_SUBTITLE = '#info h2';
  static const String DETAIL_TAGS = '.tag-container .tag';
  static const String DETAIL_PAGES = '.thumb-container img';
  static const String DETAIL_INFO = '#info';

  // Tag specific selectors
  static const String TAG_NAME = '.name';
  static const String TAG_COUNT = '.count';
  static const String TAG_TYPE = '.tag';

  // Pagination selectors
  static const String PAGINATION = '.pagination';
  static const String NEXT_PAGE = '.next';
  static const String PREV_PAGE = '.previous';
  static const String PAGE_NUMBERS = '.page';

  // Search result selectors
  static const String SEARCH_RESULTS = '.container .gallery';
  static const String SEARCH_COUNT = '#content h1';
  static const String NO_RESULTS = '.no-results';
}
```

### **2. Robust HTML Parser**
```dart
class HtmlParser {
  static List<ContentModel> parseContentList(String html) {
    final document = parse(html);
    final galleries = document.querySelectorAll(NhentaiSelectors.CONTENT_GALLERY);
    
    return galleries.map((gallery) {
      try {
        return _parseContentCard(gallery);
      } catch (e) {
        Logger().w('Failed to parse content card: $e');
        return null;
      }
    }).whereType<ContentModel>().toList();
  }

  static ContentModel _parseContentCard(Element gallery) {
    final link = gallery.querySelector(NhentaiSelectors.CONTENT_LINK);
    final cover = gallery.querySelector(NhentaiSelectors.CONTENT_COVER);
    final caption = gallery.querySelector(NhentaiSelectors.CONTENT_TITLE);

    if (link == null || cover == null || caption == null) {
      throw ParseException('Missing required elements in content card');
    }

    final id = _extractIdFromUrl(link.attributes['href'] ?? '');
    final title = caption.text.trim();
    final coverUrl = _buildImageUrl(cover.attributes['data-src'] ?? cover.attributes['src'] ?? '');

    return ContentModel(
      id: id,
      title: title,
      coverUrl: coverUrl,
      tags: [], // Will be populated in detail parsing
      artists: [],
      language: '',
      pageCount: 0,
      imageUrls: [],
      uploadDate: DateTime.now(),
      cachedAt: DateTime.now(),
    );
  }

  static ContentModel parseContentDetail(String html) {
    final document = parse(html);
    
    try {
      final info = document.querySelector(NhentaiSelectors.DETAIL_INFO);
      if (info == null) throw ParseException('Info section not found');

      final title = _parseTitle(info);
      final tags = _parseTags(document);
      final images = _parseImages(document);
      final metadata = _parseMetadata(info);

      return ContentModel(
        id: metadata['id'] ?? '',
        title: title,
        englishTitle: metadata['englishTitle'],
        japaneseTitle: metadata['japaneseTitle'],
        coverUrl: images.isNotEmpty ? images.first : '',
        tags: tags,
        artists: metadata['artists'] ?? [],
        characters: metadata['characters'] ?? [],
        parodies: metadata['parodies'] ?? [],
        groups: metadata['groups'] ?? [],
        language: metadata['language'] ?? '',
        category: metadata['category'] ?? '',
        pageCount: images.length,
        imageUrls: images,
        uploadDate: _parseDate(metadata['uploadDate']),
        favorites: int.tryParse(metadata['favorites'] ?? '0') ?? 0,
        cachedAt: DateTime.now(),
      );
    } catch (e) {
      throw ParseException('Failed to parse content detail: $e');
    }
  }

  static List<TagModel> _parseTags(Document document) {
    final tagElements = document.querySelectorAll(NhentaiSelectors.DETAIL_TAGS);
    
    return tagElements.map((tagElement) {
      try {
        final nameElement = tagElement.querySelector(NhentaiSelectors.TAG_NAME);
        final countElement = tagElement.querySelector(NhentaiSelectors.TAG_COUNT);
        
        if (nameElement == null) return null;

        final name = nameElement.text.trim();
        final count = int.tryParse(countElement?.text.replaceAll(RegExp(r'[^\d]'), '') ?? '0') ?? 0;
        final type = _determineTagType(tagElement);
        final url = tagElement.attributes['href'] ?? '';

        return TagModel(
          name: name,
          type: type,
          count: count,
          url: url,
        );
      } catch (e) {
        Logger().w('Failed to parse tag: $e');
        return null;
      }
    }).whereType<TagModel>().toList();
  }

  static List<String> _parseImages(Document document) {
    final thumbElements = document.querySelectorAll(NhentaiSelectors.DETAIL_PAGES);
    
    return thumbElements.map((thumb) {
      final dataSrc = thumb.attributes['data-src'] ?? thumb.attributes['src'] ?? '';
      return _convertThumbToFullImage(dataSrc);
    }).where((url) => url.isNotEmpty).toList();
  }

  static String _convertThumbToFullImage(String thumbUrl) {
    // Convert thumbnail URL to full image URL
    // Example: https://t.nhentai.net/galleries/123456/1t.jpg
    // To: https://i.nhentai.net/galleries/123456/1.jpg
    return thumbUrl
        .replaceAll('t.nhentai.net', 'i.nhentai.net')
        .replaceAll(RegExp(r't\.(jpg|png|gif)$'), r'.\1');
  }

  static String _determineTagType(Element tagElement) {
    final classes = tagElement.classes.toList();
    final href = tagElement.attributes['href'] ?? '';
    
    if (href.contains('/artist/')) return 'artist';
    if (href.contains('/character/')) return 'character';
    if (href.contains('/parody/')) return 'parody';
    if (href.contains('/group/')) return 'group';
    if (href.contains('/language/')) return 'language';
    if (href.contains('/category/')) return 'category';
    
    return 'tag'; // Default type
  }
}
```

### **3. Fallback Parsing**
```dart
class FallbackParser {
  static ContentModel? tryAlternativeParsing(String html) {
    final document = parse(html);
    
    // Try different selector combinations
    final alternativeSelectors = [
      {'title': 'h1', 'cover': 'img[src*="cover"]'},
      {'title': '.title', 'cover': '.cover-image'},
      {'title': '[data-title]', 'cover': '[data-cover]'},
    ];

    for (final selectors in alternativeSelectors) {
      try {
        final titleElement = document.querySelector(selectors['title']!);
        final coverElement = document.querySelector(selectors['cover']!);
        
        if (titleElement != null && coverElement != null) {
          return ContentModel(
            id: _generateFallbackId(),
            title: titleElement.text.trim(),
            coverUrl: coverElement.attributes['src'] ?? '',
            tags: [],
            artists: [],
            language: '',
            pageCount: 0,
            imageUrls: [],
            uploadDate: DateTime.now(),
            cachedAt: DateTime.now(),
          );
        }
      } catch (e) {
        continue; // Try next selector combination
      }
    }
    
    return null; // All parsing attempts failed
  }
}
```

---

## 🛡️ Cloudflare Bypass

### **1. WebView-Based Bypass**
```dart
class CloudflareBypass {
  static WebViewController? _webViewController;
  static Completer<bool>? _bypassCompleter;

  static Future<bool> bypassCloudflare() async {
    try {
      _bypassCompleter = Completer<bool>();
      
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: _onPageFinished,
          onWebResourceError: _onWebResourceError,
        ))
        ..loadRequest(Uri.parse('https://nhentai.net'));

      // Wait for bypass completion with timeout
      return await _bypassCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => false,
      );
    } catch (e) {
      Logger().e('Cloudflare bypass failed: $e');
      return false;
    }
  }

  static void _onPageFinished(String url) async {
    if (_bypassCompleter?.isCompleted == true) return;

    try {
      // Check if we've successfully bypassed Cloudflare
      final html = await _webViewController?.runJavaScriptReturningResult(
        'document.documentElement.outerHTML'
      );

      if (html != null && _isBypassSuccessful(html.toString())) {
        // Extract cookies for future requests
        await _extractCookies();
        _bypassCompleter?.complete(true);
      } else if (_isCloudflareChallenge(html?.toString() ?? '')) {
        // Still in challenge, wait for completion
        Logger().i('Cloudflare challenge detected, waiting...');
      } else {
        // Unknown state, consider failed
        _bypassCompleter?.complete(false);
      }
    } catch (e) {
      Logger().e('Error checking bypass status: $e');
      _bypassCompleter?.complete(false);
    }
  }

  static bool _isBypassSuccessful(String html) {
    // Check for indicators that we've successfully accessed the site
    return html.contains('nhentai') && 
           html.contains('gallery') && 
           !html.contains('cf-browser-verification') &&
           !html.contains('cf-challenge-running');
  }

  static bool _isCloudflareChallenge(String html) {
    return html.contains('cf-browser-verification') ||
           html.contains('cf-challenge-running') ||
           html.contains('Checking your browser');
  }

  static Future<void> _extractCookies() async {
    try {
      final cookieManager = WebViewCookieManager();
      final cookies = await cookieManager.getCookies(Uri.parse('https://nhentai.net'));
      
      // Store cookies for future HTTP requests
      for (final cookie in cookies) {
        SessionManager.addCookie(cookie);
      }
    } catch (e) {
      Logger().e('Failed to extract cookies: $e');
    }
  }
}
```

### **2. Challenge Detection**
```dart
class ChallengeDetector {
  static bool isCloudflareChallenge(String html) {
    final challengeIndicators = [
      'cf-browser-verification',
      'cf-challenge-running',
      'Checking your browser',
      'DDoS protection by Cloudflare',
      'cf-wrapper',
      'cf-error-details',
    ];

    return challengeIndicators.any((indicator) => html.contains(indicator));
  }

  static bool isRateLimited(String html, int statusCode) {
    return statusCode == 429 || 
           html.contains('Rate limited') ||
           html.contains('Too many requests');
  }

  static bool isBlocked(String html, int statusCode) {
    return statusCode == 403 ||
           html.contains('Access denied') ||
           html.contains('Forbidden');
  }

  static ChallengeType detectChallengeType(String html) {
    if (html.contains('cf-browser-verification')) {
      return ChallengeType.browserCheck;
    } else if (html.contains('cf-challenge-running')) {
      return ChallengeType.jsChallenge;
    } else if (html.contains('captcha')) {
      return ChallengeType.captcha;
    } else {
      return ChallengeType.unknown;
    }
  }
}

enum ChallengeType {
  browserCheck,
  jsChallenge,
  captcha,
  unknown,
}
```

---

## 🚨 Error Handling

### **1. Comprehensive Error Types**
```dart
abstract class ScrapingException implements Exception {
  final String message;
  final String? url;
  final int? statusCode;
  
  const ScrapingException(this.message, {this.url, this.statusCode});
}

class CloudflareException extends ScrapingException {
  const CloudflareException(String message, {String? url}) 
      : super(message, url: url);
}

class ParseException extends ScrapingException {
  const ParseException(String message, {String? url}) 
      : super(message, url: url);
}

class RateLimitException extends ScrapingException {
  final Duration retryAfter;
  
  const RateLimitException(String message, this.retryAfter, {String? url}) 
      : super(message, url: url);
}

class BlockedException extends ScrapingException {
  const BlockedException(String message, {String? url, int? statusCode}) 
      : super(message, url: url, statusCode: statusCode);
}
```

### **2. Error Recovery Strategy**
```dart
class ErrorRecovery {
  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 1);

  static Future<T> withRetry<T>(
    Future<T> Function() operation,
    {int maxAttempts = maxRetries}
  ) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxAttempts) {
          rethrow;
        }

        final delay = _calculateDelay(attempts, e);
        Logger().w('Attempt $attempts failed: $e. Retrying in ${delay.inSeconds}s...');
        
        await Future.delayed(delay);
        
        // Handle specific error types
        if (e is CloudflareException) {
          await _handleCloudflareError();
        } else if (e is RateLimitException) {
          await _handleRateLimitError(e);
        } else if (e is BlockedException) {
          await _handleBlockedError();
        }
      }
    }
    
    throw Exception('Max retry attempts exceeded');
  }

  static Duration _calculateDelay(int attempt, dynamic error) {
    if (error is RateLimitException) {
      return error.retryAfter;
    }
    
    // Exponential backoff with jitter
    final exponentialDelay = baseDelay * pow(2, attempt - 1);
    final jitter = Duration(milliseconds: Random().nextInt(1000));
    
    return exponentialDelay + jitter;
  }

  static Future<void> _handleCloudflareError() async {
    Logger().i('Handling Cloudflare error - attempting bypass...');
    await CloudflareBypass.bypassCloudflare();
  }

  static Future<void> _handleRateLimitError(RateLimitException e) async {
    Logger().i('Rate limited - waiting ${e.retryAfter.inSeconds}s...');
    ProxyManager.rotateProxy();
  }

  static Future<void> _handleBlockedError() async {
    Logger().i('Blocked - rotating proxy and user agent...');
    ProxyManager.rotateProxy();
    AntiDetection.rotateUserAgent();
  }
}
```

---

## ⚡ Performance Optimization

### **1. Concurrent Scraping**
```dart
class ConcurrentScraper {
  static const int maxConcurrentRequests = 3;
  static final Semaphore _semaphore = Semaphore(maxConcurrentRequests);

  static Future<List<T>> scrapeMultiple<T>(
    List<String> urls,
    Future<T> Function(String) scraper,
  ) async {
    final futures = urls.map((url) async {
      await _semaphore.acquire();
      try {
        return await scraper(url);
      } finally {
        _semaphore.release();
      }
    });

    return await Future.wait(futures);
  }
}

class Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}
```

### **2. Intelligent Caching**
```dart
class ScrapingCache {
  static const Duration cacheExpiry = Duration(hours: 6);
  static final Map<String, CachedResponse> _cache = {};

  static Future<String?> getCachedHtml(String url) async {
    final cached = _cache[url];
    if (cached != null && !cached.isExpired) {
      Logger().d('Cache hit for: $url');
      return cached.html;
    }
    
    _cache.remove(url); // Remove expired cache
    return null;
  }

  static void cacheHtml(String url, String html) {
    _cache[url] = CachedResponse(
      html: html,
      timestamp: DateTime.now(),
    );
    
    // Cleanup old cache entries
    _cleanupCache();
  }

  static void _cleanupCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) => 
        now.difference(value.timestamp) > cacheExpiry);
  }
}

class CachedResponse {
  final String html;
  final DateTime timestamp;

  CachedResponse({required this.html, required this.timestamp});

  bool get isExpired => 
      DateTime.now().difference(timestamp) > ScrapingCache.cacheExpiry;
}
```

### **3. Memory Management**
```dart
class MemoryManager {
  static const int maxCacheSize = 100; // Maximum cached responses
  static const int maxImageCache = 50; // Maximum cached images

  static void optimizeMemory() {
    _cleanupHtmlCache();
    _cleanupImageCache();
    _forceGarbageCollection();
  }

  static void _cleanupHtmlCache() {
    if (ScrapingCache._cache.length > maxCacheSize) {
      final sortedEntries = ScrapingCache._cache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      // Remove oldest entries
      final toRemove = sortedEntries.take(
        ScrapingCache._cache.length - maxCacheSize
      );
      
      for (final entry in toRemove) {
        ScrapingCache._cache.remove(entry.key);
      }
    }
  }

  static void _forceGarbageCollection() {
    // Force garbage collection (platform-specific)
    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platforms handle GC automatically
      Logger().d('Memory optimization completed');
    }
  }
}
```

---

## 📊 Monitoring & Analytics

### **1. Scraping Metrics**
```dart
class ScrapingMetrics {
  static int _successfulRequests = 0;
  static int _failedRequests = 0;
  static int _cloudflareBlocks = 0;
  static int _rateLimits = 0;
  static final List<Duration> _responseTimes = [];

  static void recordSuccess(Duration responseTime) {
    _successfulRequests++;
    _responseTimes.add(responseTime);
    
    // Keep only recent response times
    if (_responseTimes.length > 100) {
      _responseTimes.removeAt(0);
    }
  }

  static void recordFailure(ScrapingException exception) {
    _failedRequests++;
    
    if (exception is CloudflareException) {
      _cloudflareBlocks++;
    } else if (exception is RateLimitException) {
      _rateLimits++;
    }
  }

  static Map<String, dynamic> getMetrics() {
    return {
      'successful_requests': _successfulRequests,
      'failed_requests': _failedRequests,
      'cloudflare_blocks': _cloudflareBlocks,
      'rate_limits': _rateLimits,
      'success_rate': _successfulRequests / (_successfulRequests + _failedRequests),
      'average_response_time': _responseTimes.isEmpty ? 0 : 
          _responseTimes.reduce((a, b) => a + b).inMilliseconds / _responseTimes.length,
    };
  }
}
```

---

## 🔗 Related Documentation

- [Cloudflare Bypass](Cloudflare-Bypass) - Detailed bypass implementation
- [Data Layer Implementation](Data-Layer-Implementation) - How scraping integrates with data layer
- [Performance Optimization](Performance-Optimization) - General performance strategies
- [Security Considerations](Security-Considerations) - Security aspects of web scraping

---

**Next Steps:**
- Learn about [Cloudflare Bypass](Cloudflare-Bypass) implementation
- Explore [Data Layer Implementation](Data-Layer-Implementation)
- Check [Performance Optimization](Performance-Optimization) strategies

---

**Last Updated**: July 30, 2025  
**Author**: NhentaiApp Development Team