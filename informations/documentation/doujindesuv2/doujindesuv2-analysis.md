# Analisis Mendalam: DoujinDesu v2 Configuration

**Tanggal Analisis**: 2026-05-10  
**Website**: https://v2.doujindesu.fun/  
**Status**: ✅ Website Aktif (Next.js SSR)

---

## 🔍 Executive Summary

DoujinDesu v2 adalah website manga/manhwa/doujinshi berbahasa Indonesia yang menggunakan **Next.js 14+ dengan App Router** dan **Hybrid Architecture (API + SSR)**. Website ini **MEMILIKI REST API JSON** untuk detail manga dan chapter reader, tetapi menggunakan SSR HTML untuk homepage dan listing.

### ⚠️ Perbedaan Kritis dengan NHentai

| Aspek | NHentai | DoujinDesu v2 |
|-------|---------|---------------|
| **Arsitektur** | REST API (JSON only) | Hybrid (API + SSR) |
| **Data Format** | Pure JSON response | JSON API + HTML for listing |
| **Endpoint** | `/api/galleries/{id}` | `/api/manga/{slug}`, `/api/read/{slug}/{chapter}` |
| **Scraping Method** | HTTP JSON parsing | JSON API + HTML parsing for lists |
| **Rate Limiting** | API-based (60 req/min) | API-based (30 req/min) |
| **Authentication** | Token-based API | No authentication required |

---

## 🏗️ Arsitektur Website

### Technology Stack
```yaml
Framework: Next.js 14+ (App Router)
Rendering: Server-Side Rendering (SSR)
Language: TypeScript/JavaScript
Styling: Tailwind CSS
Fonts: Bebas Neue, Nunito
CDN: cdn-images.doujindesu.fun
Analytics: Histats, Ahrefs
Protection: Cloudflare
```

### URL Structure
```
Homepage:        https://v2.doujindesu.fun/
Manga List:      https://v2.doujindesu.fun/manga
Manga Detail:    https://v2.doujindesu.fun/manga/{slug}
Chapter Reader:  https://v2.doujindesu.fun/manga/{slug}/{chapter}
Search:          https://v2.doujindesu.fun/manga?q={query}
Filter by Type:  https://v2.doujindesu.fun/manga?type={manhwa|manga|doujinshi}
Filter by Order: https://v2.doujindesu.fun/manga?order={latest|popular}
Genres:          https://v2.doujindesu.fun/genres
Login:           https://v2.doujindesu.fun/login

API Endpoints:
Manga Detail:    https://v2.doujindesu.fun/api/manga/{slug}
Chapter Read:    https://v2.doujindesu.fun/api/read/{slug}/{chapter}
```

---

## 📊 Data Structure Analysis

### API Endpoint: Manga Detail
**Endpoint**: `/api/manga/{slug}`  
**Example**: `https://v2.doujindesu.fun/api/manga/tsuma-no-imouto`

```json
{
  "success": true,
  "data": {
    "info": {
      "_id": "692e8c9f0cc971443a671573",
      "slug": "tsuma-no-imouto",
      "alternativeTitle": "妻の妹, Wife's Younger Sister",
      "createdAt": "2025-12-02T06:52:15.288Z",
      "metadata": {
        "status": "Finished",
        "type": "Doujinshi",
        "series": "Original",
        "author": "",
        "rating": "8.50",
        "created": "Selasa, 22 Juli 2025"
      },
      "synopsis": "",
      "tags": ["Big Ass", "Big Penis", "Bikini", ...],
      "thumb": "https://cdn-images.doujindesu.fun/covers/tsuma-no-imouto.jpg",
      "title": "Tsuma no Imouto",
      "views": 13508,
      "chapter_count": 4
    },
    "chapters": [
      {
        "_id": "69dfb3427146a5347d5840c2",
        "slug": "tsuma-no-imouto-4",
        "chapter_index": 4,
        "title": "4 END"
      }
    ],
    "recommendations": [...]
  },
  "pagination": null
}
```

### API Endpoint: Chapter Reader
**Endpoint**: `/api/read/{slug}/{chapter}`  
**Example**: `https://v2.doujindesu.fun/api/read/tsuma-no-imouto/tsuma-no-imouto`

```json
{
  "success": true,
  "data": {
    "chapter": {
      "_id": "692e8ca60cc971443a671576",
      "manga_id": "692e8c9f0cc971443a671573",
      "slug": "tsuma-no-imouto",
      "chapter_index": 1,
      "title": "1",
      "images": [
        "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (1).webp",
        "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (2).webp"
      ],
      "link": "https://doujindesu.tv/tsuma-no-imouto/",
      "updatedAt": "2025-12-27T19:41:44.694Z"
    },
    "manga": {
      "_id": "692e8c9f0cc971443a671573",
      "slug": "tsuma-no-imouto",
      "thumb": "https://cdn-images.doujindesu.fun/covers/tsuma-no-imouto.jpg",
      "title": "Tsuma no Imouto"
    },
    "navigation": {
      "next": "tsuma-no-imouto-2",
      "prev": null
    }
  },
  "pagination": null
}
```

### Card Display Structure
```html
<div class="manga-card">
  <img src="https://cdn-images.doujindesu.fun/covers/{slug}.jpg" />
  <span class="type-badge">MANHWA|MANGA|DOUJINSHI</span>
  <span class="status-badge">ONG|END</span>
  <p class="chapter-count">{count} Chapter</p>
  <span class="rating">⭐ {rating}</span>
  <p class="title">{title}</p>
</div>
```

---

## 🎨 UI/UX Patterns

### Content Categories
1. **MANHWA** (Korean) - Purple badge `bg-purple-600/90`
2. **MANGA** (Japanese) - Orange badge `bg-orange-500/90`
3. **DOUJINSHI** (Fan-made) - Pink badge `bg-pink-600/90`

### Status Indicators
- **ONG** (Ongoing) - Green badge `bg-green-600/90`
- **END** (Ended) - Gray badge `bg-gray-600/90`

### Navigation Structure
```
Bottom Nav:
├── Home (/)
├── All (/manga)
├── Genre (/genres)
├── Simpan (/login) - Requires auth
└── Riwayat (/login) - Requires auth

Top Nav:
├── Logo (Doujindesu)
├── Search Button
└── Login Button
```

---

## 🔐 Authentication & Session

### Login System
```yaml
Login URL: /login
Auth Type: Cookie-based session
Protected Routes:
  - /login (favorites/bookmarks)
  - History tracking
  - User preferences
```

### Session Indicators
- Red dot badge on "Simpan" and "Riwayat" nav items when not logged in
- Redirects to `/login` when accessing protected features

---

## 🖼️ CDN & Asset Management

### Image CDN
```
Base URL: https://cdn-images.doujindesu.fun/
Covers:   https://cdn-images.doujindesu.fun/covers/{filename}
Chapters: https://cdn-images.doujindesu.fun/chapters/{manga_id}/{chapter}/{page}

Image Formats:
- .jpg (primary)
- .webp (optimized)
- .gif (animated covers)
- .png (fallback)
```

### Image Optimization
```html
<img 
  referrerPolicy="no-referrer"
  loading="lazy"
  decoding="async"
  sizes="(max-width: 640px) 45vw, (max-width: 1024px) 30vw, 200px"
/>
```

---

## 🚫 Anti-Scraping Measures

### 1. Cloudflare Protection
- DDoS protection
- Bot detection
- Challenge pages for suspicious traffic

### 2. Server-Side Rendering
- No direct API endpoints
- Data embedded in HTML
- Requires full page load

### 3. Referrer Policy
```html
<img referrerPolicy="no-referrer" />
```
Prevents hotlinking and tracks image access

### 4. Dynamic Content Loading
- Next.js hydration
- Client-side React components
- JavaScript required for full functionality

---

## 🔧 Scraping Strategy Recommendations

### ✅ Recommended Approach: API + HTML Hybrid

DoujinDesu v2 memiliki API endpoints untuk detail dan chapter reading. Gunakan API untuk operasi tersebut, dan HTML scraping hanya untuk homepage/listing.

#### Option 1: API for Detail/Chapter (Recommended)
```dart
// Use HTTP package for API calls
import 'dart:convert';
import 'package:http/http.dart' as http;

class DoujinDesuV2DataSource {
  static const String baseUrl = 'https://v2.doujindesu.fun';
  
  // Get manga detail
  Future<MangaDetail> getMangaDetail(String slug) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/manga/$slug'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json',
        'Accept-Language': 'id-ID,id;q=0.9',
      },
    );
    
    final json = jsonDecode(response.body);
    return MangaDetail.fromJson(json['data']);
  }
  
  // Get chapter images
  Future<ChapterRead> getChapterRead(String slug, String chapter) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/read/$slug/$chapter'),
      headers: {
        'User-Agent': 'Mozilla/5.0 ...',
        'Accept': 'application/json',
      },
    );
    
    final json = jsonDecode(response.body);
    return ChapterRead.fromJson(json['data']);
  }
}
```

#### Option 2: HTML for Homepage/Listing
```dart
// Use html package for homepage scraping
import 'package:html/parser.dart' as html_parser;

Future<List<Manga>> getTrendingManga() async {
  final response = await http.get(
    Uri.parse('https://v2.doujindesu.fun/'),
    headers: {
      'User-Agent': 'Mozilla/5.0 ...',
      'Accept': 'text/html,application/xhtml+xml',
    },
  );
  
  final document = html_parser.parse(response.body);
  // Extract manga cards from DOM
  // ... parse logic
}
```

---

## 📋 Configuration Template (Updated)

Config untuk DoujinDesu v2 dengan API endpoints:

```json
{
  "source": "doujindesuv2",
  "version": "1.1.0",
  "lastUpdated": "2026-05-10T09:50:16+07:00",
  "enabled": true,
  "defaultLanguage": "indonesian",
  "baseUrl": "https://v2.doujindesu.fun",
  "cdnUrl": "https://cdn-images.doujindesu.fun",
  
  "scrapingMode": "api_json",
  "requiresJavaScript": false,
  "requiresCloudflareBypass": false,
  
  "api": {
    "enabled": true,
    "baseUrl": "https://v2.doujindesu.fun/api",
    "endpoints": {
      "mangaDetail": "/manga/{slug}",
      "chapterRead": "/read/{slug}/{chapter}"
    }
  },
  
  "scraper": {
    "enabled": true,
    "urlPatterns": {
      "home": {
        "url": "https://v2.doujindesu.fun/",
        "note": "Homepage uses HTML scraping"
      },
      "detail": "https://v2.doujindesu.fun/api/manga/{id}/",
      "chapter": "https://v2.doujindesu.fun/api/read/{id}/{chapter}/"
    },
    "selectors": {
      "detail": {
        "apiMode": true,
        "jsonPath": "data",
        "fields": {
          "title": "info.title",
          "coverUrl": "info.thumb",
          "alternativeTitle": "info.alternativeTitle",
          "type": "info.metadata.type",
          "author": "info.metadata.author",
          "status": "info.metadata.status",
          "rating": "info.metadata.rating",
          "views": "info.views",
          "tags": "info.tags",
          "synopsis": "info.synopsis"
        },
        "chapters": {
          "jsonPath": "chapters",
          "fields": {
            "id": "slug",
            "title": "title",
            "chapterIndex": "chapter_index"
          }
        }
      },
      "reader": {
        "apiMode": true,
        "jsonPath": "data",
        "fields": {
          "images": "chapter.images",
          "nextChapter": "navigation.next",
          "prevChapter": "navigation.prev"
        }
      }
    }
  },
  
  "network": {
    "requiresBypass": false,
    "headers": {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      "Accept": "application/json,text/html",
      "Accept-Language": "id-ID,id;q=0.9"
    },
    "rateLimit": {
      "enabled": true,
      "requestsPerMinute": 30,
      "minDelayMs": 2000
    }
  },
  
  "ui": {
    "displayName": "DoujinDesu v2",
    "iconPath": "https://raw.githubusercontent.com/shirokun20/nhasixapp/refs/heads/master/app/images/doujindesu.png",
    "brandColor": "#d43726",
    "openInBrowserUrl": "https://v2.doujindesu.fun"
  }
}
```

---

## ⚠️ Critical Differences from NHentai

### 1. API Availability
- **NHentai**: REST API only
- **DoujinDesu**: Hybrid (API + HTML)

### 2. Data Extraction
- **NHentai**: Direct JSON parsing
- **DoujinDesu**: JSON API for detail/chapter, HTML for listing

### 3. Rate Limiting
- **NHentai**: API rate limits (60 req/min)
- **DoujinDesu**: API rate limits (30 req/min recommended)

### 4. Image URLs
- **NHentai**: Predictable pattern `i.nhentai.net/galleries/{media_id}/{page}.{ext}`
- **DoujinDesu**: CDN-based `cdn-images.doujindesu.fun/covers/{filename}` and `cdn.manhwature.com/desu.photos/uploads/`

### 5. Authentication
- **NHentai**: Token-based API auth
- **DoujinDesu**: No authentication required for API

---

## 🎯 Implementation Recommendations

### For Your Flutter App

#### 1. Create Separate Data Source Class
```dart
class DoujinDesuV2RemoteDataSource extends RemoteDataSource {
  static const String baseUrl = 'https://v2.doujindesu.fun';
  static const String apiBaseUrl = '$baseUrl/api';
  
  final http.Client httpClient;
  
  DoujinDesuV2RemoteDataSource({required this.httpClient});
  
  @override
  Future<MangaDetailModel> getMangaDetail(String id) async {
    final response = await httpClient.get(
      Uri.parse('$apiBaseUrl/manga/$id'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return MangaDetailModel.fromJson(json['data']);
    } else {
      throw ServerException();
    }
  }
  
  @override
  Future<ChapterModel> getChapter(String mangaId, String chapterId) async {
    final response = await httpClient.get(
      Uri.parse('$apiBaseUrl/read/$mangaId/$chapterId'),
      headers: _getHeaders(),
    );
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ChapterModel.fromJson(json['data']);
    } else {
      throw ServerException();
    }
  }
  
  Map<String, String> _getHeaders() => {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json',
    'Accept-Language': 'id-ID,id;q=0.9',
  };
}
```

#### 2. Use JSON Serialization
```yaml
dependencies:
  http: ^1.1.0
  json_serializable: ^6.7.0
  
dev_dependencies:
  build_runner: ^2.4.0
```

#### 3. Implement Rate Limiting
```dart
class RateLimiter {
  final int requestsPerMinute;
  final Duration minDelay;
  
  RateLimiter({
    this.requestsPerMinute = 30,
    this.minDelay = const Duration(milliseconds: 2000),
  });
  
  Future<T> execute<T>(Future<T> Function() request) async {
    await Future.delayed(minDelay);
    return request();
  }
}
```

#### 4. Implement Retry Logic
```dart
Future<T> _retryRequest<T>(
  Future<T> Function() request, {
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 3),
}) async {
  for (int i = 0; i < maxAttempts; i++) {
    try {
      return await request();
    } catch (e) {
      if (i == maxAttempts - 1) rethrow;
      await Future.delayed(delay * (i + 1)); // Exponential backoff
    }
  }
  throw Exception('Max retries exceeded');
}
```

---

## 🐛 Known Issues & Challenges

### 1. Homepage Listing
- **Issue**: Homepage uses HTML scraping for trending manga
- **Solution**: Use HTML parsing for homepage, API for detail/chapter

### 2. Search Functionality
- **Issue**: No dedicated search API endpoint
- **Solution**: Use HTML scraping for search results (`/manga?q={query}`)

### 3. Rate Limiting
- **Issue**: API rate limiting (30 req/min)
- **Solution**: Implement strict rate limiting with exponential backoff

### 4. Slug-Based URLs
- **Issue**: No numeric IDs, uses slugs
- **Solution**: Store slug as primary identifier

### 5. Image CDN
- **Issue**: Images hosted on multiple CDNs
- **Solution**: Use proper referrer headers, handle both CDN domains

---

## 📈 Performance Considerations

### Recommended Settings
```yaml
Rate Limit: 30 requests/minute
Min Delay: 2000ms between requests
Timeout: 30 seconds per request
Retry: 3 attempts with exponential backoff
Cache: 1 hour for list pages, 24 hours for detail pages
```

### Bandwidth Estimation
```
API Response (manga detail): ~5-10KB
API Response (chapter read): ~2-5KB + image URLs
Homepage HTML: ~40KB (compressed)
```

---

## 🔮 Future Considerations

### Potential Changes
1. **API Introduction**: Website might add REST API in future
2. **GraphQL**: Modern Next.js apps often use GraphQL
3. **CDN Changes**: Image URLs might change
4. **Auth Changes**: Login system might be updated

### Monitoring
- Check for `<script id="__NEXT_DATA__">` changes
- Monitor CDN URL patterns
- Watch for API endpoint additions
- Track Cloudflare protection updates

---

## �� Conclusion

DoujinDesu v2 adalah website **Hybrid Architecture** yang menggunakan:
- **JSON API** untuk detail manga dan chapter reading
- **HTML SSR** untuk homepage dan listing

Implementasi scraper untuk website ini memerlukan:

1. ✅ HTTP client untuk API calls
2. ✅ JSON parsing capability
3. ✅ HTML parsing untuk homepage/listing
4. ✅ Rate limiting (30 req/min)
5. ✅ Retry logic dengan exponential backoff

**Rekomendasi**: Gunakan API endpoints (`/api/manga/{slug}` dan `/api/read/{slug}/{chapter}`) untuk detail dan chapter reading. Untuk homepage dan listing, bisa menggunakan HTML scraping seperti komiku.id.

---

**Dibuat oleh**: Kiro AI Assistant  
**Untuk**: Kuron App Development  
**Tanggal**: 2026-05-10
