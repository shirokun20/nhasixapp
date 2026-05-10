# Panduan Implementasi: DoujinDesu v2 Scraper

**Status**: Draft - Siap untuk review  
**Target**: Flutter/Dart Implementation  
**Last Updated**: 2026-05-10

---

## 📋 Checklist Implementasi

### Phase 1: Core Setup
- [ ] Setup HTML parsing library (`html` package)
- [ ] Configure rate limiter (30 req/min)
- [ ] Setup cookie persistence
- [ ] Implement Cloudflare bypass strategy

### Phase 2: Data Extraction
- [ ] Parse Next.js embedded JSON from `<script>` tags
- [ ] Extract manga list from trending sections
- [ ] Extract manga detail from page content
- [ ] Extract chapter list from detail page

### Phase 3: Feature Implementation
- [ ] Search functionality
- [ ] Filter by type (manga/manhwa/doujinshi)
- [ ] Filter by order (latest/popular)
- [ ] Pagination support
- [ ] Authentication flow

### Phase 4: Optimization
- [ ] Implement caching layer
- [ ] Image lazy loading
- [ ] Error handling & retry logic
- [ ] Performance monitoring

---

## 🛠️ Core Implementation

### 1. Setup Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  html: ^0.15.4
  dio: ^5.4.0  # Optional, for better error handling
  path_provider: ^2.1.2  # For caching
  shared_preferences: ^2.2.2  # For cookies
```

### 2. Rate Limiter Implementation

```dart
// lib/core/utils/rate_limiter.dart
class RateLimiter {
  final int requestsPerMinute;
  final Duration minDelay;
  final Duration cooldownDuration;
  
  DateTime? _lastRequestTime;
  DateTime? _cooldownUntil;
  int _consecutiveErrors = 0;
  
  RateLimiter({
    this.requestsPerMinute = 30,
    this.minDelay = const Duration(seconds: 2),
    this.cooldownDuration = const Duration(minutes: 10),
  });
  
  Future<void> wait() async {
    // Check if in cooldown
    if (_cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!)) {
      final waitTime = _cooldownUntil!.difference(DateTime.now()).inMilliseconds;
      await Future.delayed(Duration(milliseconds: waitTime));
    }
    
    // Apply min delay between requests
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < minDelay) {
        await Future.delayed(minDelay - elapsed);
      }
    }
    
    _lastRequestTime = DateTime.now();
  }
  
  void recordError() {
    _consecutiveErrors++;
    if (_consecutiveErrors >= 3) {
      _cooldownUntil = DateTime.now().add(cooldownDuration);
    }
  }
  
  void recordSuccess() {
    _consecutiveErrors = 0;
    _cooldownUntil = null;
  }
}
```

### 3. Cloudflare Bypass Strategy

```dart
// lib/data/datasources/remote/doujindesu_v2_scraper.dart
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class DoujinDesuV2Scraper {
  final RateLimiter rateLimiter;
  final Map<String, String> _cookies = {};
  
  DoujinDesuV2Scraper({RateLimiter? rateLimiter})
      : rateLimiter = rateLimiter ?? RateLimiter();
  
  Map<String, String> get _defaultHeaders => {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
    'Accept-Encoding': 'gzip, deflate, br',
    'DNT': '1',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Cache-Control': 'max-age=0',
  };
  
  Future<http.Response> _get(String url) async {
    await rateLimiter.wait();
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        ..._defaultHeaders,
        if (_cookies.isNotEmpty) 'Cookie': _cookies.entries.map((e) => '${e.key}=${e.value}').join('; '),
      },
    );
    
    // Update cookies from response
    if (response.headers['set-cookie'] != null) {
      final cookies = _parseCookies(response.headers['set-cookie']!);
      _cookies.addAll(cookies);
    }
    
    if (response.statusCode == 429) {
      rateLimiter.recordError();
      throw RateLimitException('Too many requests');
    }
    
    rateLimiter.recordSuccess();
    return response;
  }
  
  Map<String, String> _parseCookies(String setCookieHeader) {
    final cookies = <String, String>{};
    final cookieStrings = setCookieHeader.split(',');
    for (final cookieString in cookieStrings) {
      final parts = cookieString.split(';');
      if (parts.isNotEmpty) {
        final nameValue = parts[0].split('=');
        if (nameValue.length == 2) {
          cookies[nameValue[0].trim()] = nameValue[1].trim();
        }
      }
    }
    return cookies;
  }
}
```

### 4. Next.js Data Extraction

```dart
// Extract data from Next.js embedded JSON
String _extractNextJsData(String htmlContent) {
  final document = html_parser.parse(htmlContent);
  final scripts = document.querySelectorAll('script');
  
  for (var script in scripts) {
    if (script.text.contains('self.__next_f.push')) {
      // Extract JSON from Next.js payload
      // Pattern: self.__next_f.push([1,"{...}"])
      final regex = RegExp(r'self\.__next_f\.push\(\[1,"([^"]+)"\]\)');
      final match = regex.firstMatch(script.text);
      if (match != null) {
        // Decode the escaped JSON string
        final encoded = match.group(1);
        if (encoded != null) {
          // This is a simplified extraction - real implementation needs more robust parsing
          return encoded;
        }
      }
    }
  }
  
  return '';
}

// Alternative: Extract from __NEXT_DATA__ script tag
Map<String, dynamic>? _extractNextData(String htmlContent) {
  final document = html_parser.parse(htmlContent);
  final scriptTags = document.querySelectorAll('script');
  
  for (var script in scriptTags) {
    if (script.text.contains('__NEXT_DATA__')) {
      final regex = RegExp(r'window\.__NEXT_DATA__\s*=\s*({.*?});');
      final match = regex.firstMatch(script.text);
      if (match != null) {
        try {
          final jsonStr = match.group(1);
          if (jsonStr != null) {
            return json.decode(jsonStr);
          }
        } catch (e) {
          // Handle parse error
        }
      }
    }
  }
  
  return null;
}
```

### 5. Manga List Scraping

```dart
// lib/data/datasources/remote/doujindesu_v2_scraper.dart
Future<List<Manga>> fetchMangaList({
  String type = 'all',
  String order = 'latest',
  int page = 1,
}) async {
  final url = Uri.parse('https://v2.doujindesu.fun/manga')
    .replace(
      queryParameters: {
        if (type != 'all') 'type': type,
        'order': order,
        'page': page.toString(),
      },
    );
  
  final response = await _get(url.toString());
  
  if (response.statusCode != 200) {
    throw Exception('Failed to load manga list');
  }
  
  final document = html_parser.parse(response.body);
  final mangas = <Manga>[];
  
  // Find all manga cards
  final cardElements = document.querySelectorAll('.flex-none.w-\\[120px\\].snap-start');
  
  for (var card in cardElements) {
    try {
      final link = card.querySelector('a.group.block');
      final titleElement = card.querySelector('.text-\\[11px\\].font-bold.text-text-primary');
      final image = card.querySelector('img[alt]');
      final typeBadge = card.querySelector('.bg-purple-600\\/90, .bg-orange-500\\/90, .bg-pink-600\\/90');
      final statusBadge = card.querySelector('.bg-green-600\\/90, .bg-gray-600\\/90');
      final chapterElement = card.querySelector('.text-white\\/90.text-\\[10px\\].font-semibold');
      final ratingElement = card.querySelector('.text-\\[10px\\].text-text-secondary.font-semibold');
      
      final manga = Manga(
        id: link?.attributes['href']?.split('/').last ?? '', // slug as id
        title: titleElement?.text.trim() ?? '',
        coverUrl: image?.attributes['src'] ?? '',
        type: _parseType(typeBadge?.text),
        status: _parseStatus(statusBadge?.text),
        chapterCount: _parseChapterCount(chapterElement?.text),
        rating: _parseRating(ratingElement?.text),
        slug: link?.attributes['href']?.split('/').last ?? '',
      );
      
      mangas.add(manga);
    } catch (e) {
      // Skip malformed cards
      continue;
    }
  }
  
  return mangas;
}

MangaType _parseType(String? typeText) {
  switch (typeText?.toLowerCase()) {
    case 'manhwa':
      return MangaType.manhwa;
    case 'doujinshi':
      return MangaType.doujinshi;
    default:
      return MangaType.manga;
  }
}

MangaStatus _parseStatus(String? statusText) {
  switch (statusText?.toLowerCase()) {
    case 'end':
      return MangaStatus.ended;
    default:
      return MangaStatus.ongoing;
  }
}

int? _parseChapterCount(String? text) {
  if (text == null) return null;
  final match = RegExp(r'(\d+)').firstMatch(text);
  return match?.group(0)?.toInt();
}

double? _parseRating(String? text) {
  if (text == null) return null;
  final match = RegExp(r'(\d+\.?\d*)').firstMatch(text);
  return match?.group(0)?.toDouble();
}
```

### 6. Manga Detail Scraping

```dart
Future<MangaDetail> fetchMangaDetail(String slug) async {
  final url = 'https://v2.doujindesu.fun/manga/$slug';
  final response = await _get(url);
  
  if (response.statusCode != 200) {
    throw Exception('Failed to load manga detail');
  }
  
  final document = html_parser.parse(response.body);
  
  final titleElement = document.querySelector('.font-display.text-xl.tracking-widest');
  final coverElement = document.querySelector('img[alt]');
  final authorElement = document.querySelector('span:contains("Author")');
  final ratingElement = document.querySelector('.flex.items-center.gap-1 svg + span');
  final synopsisElement = document.querySelector('.text-text-secondary');
  
  return MangaDetail(
    title: titleElement?.text.trim() ?? '',
    coverUrl: coverElement?.attributes['src'] ?? '',
    author: authorElement?.text.trim() ?? '',
    rating: _parseRating(ratingElement?.text),
    synopsis: synopsisElement?.text.trim() ?? '',
    slug: slug,
  );
}
```

---

## 🧪 Testing

### Test Cases

```dart
// test/data/datasources/doujindesu_v2_scraper_test.dart
void main() {
  late DoujinDesuV2Scraper scraper;
  
  setUp(() {
    scraper = DoujinDesuV2Scraper();
  });
  
  test('fetchMangaList returns list of mangas', () async {
    final mangas = await scraper.fetchMangaList();
    expect(mangas.isNotEmpty, true);
    expect(mangas.every((m) => m.title.isNotEmpty), true);
  });
  
  test('fetchMangaDetail returns correct data', () async {
    final detail = await scraper.fetchMangaDetail('secret-class');
    expect(detail.title, isNotEmpty);
    expect(detail.coverUrl, isNotEmpty);
  });
  
  test('rate limiting works correctly', () async {
    final limiter = RateLimiter(requestsPerMinute: 60);
    
    final start = DateTime.now();
    for (int i = 0; i < 10; i++) {
      await limiter.wait();
    }
    final end = DateTime.now();
    
    // Should take at least 9 seconds (10 requests with 1s delay)
    expect(end.difference(start).inSeconds, greaterThanOrEqualTo(9));
  });
}
```

---

## 📦 Integration with Existing Codebase

### Update RemoteDataSource

```dart
// lib/data/datasources/remote/remote_data_source.dart
abstract class RemoteDataSource {
  Future<List<Manga>> fetchMangaList({
    String? type,
    String? order,
    int? page,
  });
  
  Future<MangaDetail> fetchMangaDetail(String id);
  
  Future<List<Manga>> search(String query);
}

// lib/data/datasources/remote/doujindesu_v2_data_source.dart
class DoujinDesuV2DataSource implements RemoteDataSource {
  final DoujinDesuV2Scraper scraper;
  
  DoujinDesuV2DataSource({required this.scraper});
  
  @override
  Future<List<Manga>> fetchMangaList({
    String? type,
    String? order,
    int? page,
  }) async {
    return scraper.fetchMangaList(
      type: type ?? 'all',
      order: order ?? 'latest',
      page: page ?? 1,
    );
  }
  
  @override
  Future<MangaDetail> fetchMangaDetail(String id) async {
    return scraper.fetchMangaDetail(id);
  }
  
  @override
  Future<List<Manga>> search(String query) async {
    return scraper.search(query);
  }
}
```

---

## ⚠️ Critical Notes

### 1. Don't Use JSON API Approach
```dart
// ❌ WRONG - This won't work
final response = await http.get('https://v2.doujindesu.fun/api/manga');
// Returns HTML, not JSON!

// ✅ CORRECT - HTML parsing
final response = await http.get('https://v2.doujindesu.fun/manga');
final document = html_parser.parse(response.body);
```

### 2. Respect Rate Limits
```dart
// Always wait between requests
await rateLimiter.wait();
final response = await http.get(url);
```

### 3. Handle Cloudflare
```dart
// If you get 429, wait longer
if (response.statusCode == 429) {
  await Future.delayed(Duration(minutes: 5));
  // Retry
}
```

### 4. Cache Aggressively
```dart
// Cache list pages for 1 hour
// Cache detail pages for 24 hours
// Cache images for 7 days
```

---

## 📚 References

- [HTML package documentation](https://pub.dev/packages/html)
- [HTTP package documentation](https://pub.dev/packages/http)
- [Next.js Data Fetching](https://nextjs.org/docs/basic-features/data-fetching)
- [DoujinDesu v2 Analysis](./doujindesuv2-analysis.md)

---

**Status**: Ready for implementation  
**Next Steps**: 
1. Setup HTML parsing library
2. Implement basic scraper
3. Test with real website
4. Integrate with existing data layer
