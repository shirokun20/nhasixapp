# DoujinDesu v2 - API Reference

**Base URL**: `https://v2.doujindesu.fun/api`  
**Version**: 1.0  
**Last Updated**: 2026-05-10  
**Authentication**: Not required

---

## 📚 Table of Contents

1. [Overview](#overview)
2. [API Endpoints](#api-endpoints)
3. [Data Models](#data-models)
4. [Error Handling](#error-handling)
5. [Rate Limiting](#rate-limiting)
6. [Code Examples](#code-examples)

---

## Overview

DoujinDesu v2 menyediakan REST API untuk mengakses detail manga dan chapter reading. API ini mengembalikan response dalam format JSON.

### Base Information
- **Protocol**: HTTPS
- **Format**: JSON
- **Authentication**: None
- **Rate Limit**: 30 requests/minute (recommended)

---

## API Endpoints

### 0. Get Manga List (Paginated)

Mendapatkan daftar manga dengan pagination dan filter opsional.

**Endpoint**: `GET /api/manga-list?limit={limit}&page={page}&q={query}`

**Parameters**:
- `limit` (integer, optional): Results per page (default: 24)
- `page` (integer, optional): Page number (default: 1)
- `q` (string, optional): Search query

**Example Requests**:
```http
# Get all manga (default pagination)
GET https://v2.doujindesu.fun/api/manga-list?limit=8

# Get manga with search
GET https://v2.doujindesu.fun/api/manga-list?q=ne&limit=8

# Get specific page
GET https://v2.doujindesu.fun/api/manga-list?limit=8&page=2
```

**Example Response**:
```json
{
  "success": true,
  "data": [
    {
      "_id": "69fdea77f64532fbd3d04e1b",
      "slug": "new-town-massage",
      "metadata": {
        "status": "Publishing",
        "type": "Manhwa",
        "series": "Manhwa",
        "author": "Basasak, Secret Service",
        "rating": "8.80",
        "created": "Jumat, 08 Mei 2026"
      },
      "tags": ["Ahegao", "Big Ass", "Big Breast", ...],
      "thumb": "https://cdn-images.doujindesu.fun/covers/new-town-massage.jpg",
      "title": "New Town Massage",
      "updatedAt": "2026-05-08T13:51:47.346Z",
      "views": 5843,
      "chapter_count": 8,
      "last_chapter": {
        "title": "8",
        "slug": "new-town-massage-chapter-08",
        "chapter_index": 8,
        "createdAt": "2026-05-08T13:52:34.736Z"
      }
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 117,
    "totalItems": 932,
    "perPage": 8
  }
}
```

**Response Fields**:
- `success` (boolean): Request status
- `data` (array): Array of manga results
  - `_id` (string): MongoDB ObjectId
  - `slug` (string): Manga slug
  - `title` (string): Manga title
  - `thumb` (string): Thumbnail URL
  - `tags` (array): Array of tags
  - `metadata` (object): Metadata
    - `status` (string): Publishing status
    - `type` (string): Content type
    - `series` (string): Series name
    - `author` (string): Author name
    - `rating` (string): Rating (0-10)
    - `created` (string): Creation date
  - `views` (number): View count
  - `chapter_count` (number): Total chapters
  - `last_chapter` (object): Latest chapter info
    - `title` (string): Chapter title
    - `slug` (string): Chapter slug
    - `chapter_index` (number): Chapter number
    - `createdAt` (string): ISO datetime
- `pagination` (object): Pagination info
  - `currentPage` (number): Current page
  - `totalPages` (number): Total pages
  - `totalItems` (number): Total results
  - `perPage` (number): Results per page

---

### 1. Get Manga Detail

Mendapatkan informasi lengkap tentang manga termasuk metadata, chapters, dan recommendations.

**Endpoint**: `GET /api/manga/{slug}`

**Parameters**:
- `slug` (string, required): URL-friendly identifier manga

**Example Request**:
```http
GET https://v2.doujindesu.fun/api/manga/tsuma-no-imouto
Accept: application/json
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
```

**Example Response**:
```json
{
  "success": true,
  "data": {
    "info": {
      "_id": "692e8c9f0cc971443a671573",
      "slug": "tsuma-no-imouto",
      "__v": 0,
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
      "tags": [
        "Big Ass",
        "Big Penis",
        "Bikini",
        "Blackmail",
        "Cheating",
        "Condom",
        "Impregnation",
        "Incest",
        "Inseki",
        "Multi-work Series",
        "Muscle",
        "Nakadashi",
        "Netorare",
        "Paizuri",
        "Pregnant",
        "School Uniform",
        "Sister",
        "Sole Female",
        "Sole Male",
        "Stocking",
        "Swimsuit",
        "Big Breast"
      ],
      "thumb": "https://cdn-images.doujindesu.fun/covers/tsuma-no-imouto.jpg",
      "title": "Tsuma no Imouto",
      "updatedAt": "2026-04-15T15:48:13.093Z",
      "views": 13508,
      "sql_id": 257,
      "chapter_count": 4
    },
    "chapters": [
      {
        "_id": "69dfb3427146a5347d5840c2",
        "slug": "tsuma-no-imouto-4",
        "chapter_index": 4,
        "createdAt": "2026-04-15T15:48:18.016Z",
        "title": "4 END"
      },
      {
        "_id": "692e8ca10cc971443a671574",
        "slug": "tsuma-no-imouto-3",
        "chapter_index": 3,
        "createdAt": "2025-12-02T06:52:17.702Z",
        "title": "3 END"
      },
      {
        "_id": "692e8ca40cc971443a671575",
        "slug": "tsuma-no-imouto-2",
        "chapter_index": 2,
        "createdAt": "2025-12-02T06:52:20.126Z",
        "title": "2"
      },
      {
        "_id": "692e8ca60cc971443a671576",
        "slug": "tsuma-no-imouto",
        "chapter_index": 1,
        "createdAt": "2025-12-02T06:52:22.647Z",
        "title": "1"
      }
    ],
    "recommendations": [
      {
        "_id": "695335d967a31c9f38388e46",
        "slug": "sensei-trale-hossuru-karada",
        "metadata": {
          "status": "Finished",
          "type": "Doujinshi",
          "series": "Original",
          "author": "Neko Samurai",
          "rating": "7.60",
          "created": "Sabtu, 30 Sep 2023"
        },
        "thumb": "https://cdn-images.doujindesu.fun/covers/sensei-trale-hossuru-karada.jpg",
        "title": "Sensei Trale ~Hossuru Karada~",
        "views": 538,
        "chapter_count": 1
      }
    ]
  },
  "pagination": null
}
```

**Response Fields**:
- `success` (boolean): Request status
- `data.info` (object): Manga information
  - `_id` (string): MongoDB ObjectId
  - `slug` (string): URL-friendly identifier
  - `title` (string): Manga title
  - `alternativeTitle` (string): Alternative titles (comma-separated)
  - `thumb` (string): Thumbnail URL
  - `metadata` (object): Additional metadata
    - `status` (string): Publishing status (Finished, Publishing, Ongoing)
    - `type` (string): Content type (Manga, Manhwa, Doujinshi)
    - `series` (string): Series name or "Original"
    - `author` (string): Author name
    - `rating` (string): Rating (0-10)
    - `created` (string): Creation date (formatted)
  - `synopsis` (string): Description/synopsis
  - `tags` (array): Array of tags
  - `views` (number): View count
  - `chapter_count` (number): Total chapters
- `data.chapters` (array): List of chapters
  - `_id` (string): Chapter MongoDB ObjectId
  - `slug` (string): Chapter slug
  - `chapter_index` (number): Chapter number
  - `title` (string): Chapter title
  - `createdAt` (string): ISO datetime
- `data.recommendations` (array): Recommended manga

---

### 2. Search Manga

Mencari manga berdasarkan query string.

**Endpoint**: `GET /api/search?q={query}`

**Parameters**:
- `q` (string, required): Search query

**Example Request**:
```http
GET https://v2.doujindesu.fun/api/search?q=naruto
Accept: application/json
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
```

**Example Response**:
```json
{
  "success": true,
  "data": [
    {
      "_id": "69304f990cc971443a671cb8",
      "slug": "narutop-106",
      "metadata": {
        "status": "Finished",
        "type": "Doujinshi",
        "series": "Naruto",
        "author": "Sahara Wataru",
        "rating": "7.90",
        "created": "Kamis, 02 Oktober 2025"
      },
      "thumb": "https://cdn-images.doujindesu.fun/covers/narutop-106.jpg",
      "title": "NARUTOP 106",
      "chapter_count": 1
    },
    {
      "_id": "6950b23967a31c9f38387df0",
      "slug": "narutop-pink",
      "metadata": {
        "status": "Finished",
        "type": "Doujinshi",
        "series": "Naruto",
        "author": "Sahara Wataru",
        "rating": "7.90",
        "created": "Selasa, 22 Oktober 2024"
      },
      "thumb": "https://cdn-images.doujindesu.fun/covers/narutop-pink.gif",
      "title": "NARUTOP PINK",
      "chapter_count": 2
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 1,
    "totalItems": 4,
    "perPage": 24
  }
}
```

**Response Fields**:
- `success` (boolean): Request status
- `data` (array): Array of manga results
  - `_id` (string): MongoDB ObjectId
  - `slug` (string): Manga slug
  - `title` (string): Manga title
  - `thumb` (string): Thumbnail URL
  - `metadata` (object): Metadata
    - `status` (string): Publishing status
    - `type` (string): Content type
    - `series` (string): Series name
    - `author` (string): Author name
    - `rating` (string): Rating (0-10)
    - `created` (string): Creation date
  - `chapter_count` (number): Total chapters
- `pagination` (object): Pagination info
  - `currentPage` (number): Current page
  - `totalPages` (number): Total pages
  - `totalItems` (number): Total results
  - `perPage` (number): Results per page

---

### 3. Get Chapter Content

Mendapatkan daftar gambar untuk chapter tertentu beserta navigasi.

**Endpoint**: `GET /api/read/{slug}/{chapter}`

**Parameters**:
- `slug` (string, required): Manga slug
- `chapter` (string, required): Chapter slug

**Example Request**:
```http
GET https://v2.doujindesu.fun/api/read/tsuma-no-imouto/tsuma-no-imouto
Accept: application/json
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
```

**Example Response**:
```json
{
  "success": true,
  "data": {
    "chapter": {
      "_id": "692e8ca60cc971443a671576",
      "manga_id": "692e8c9f0cc971443a671573",
      "slug": "tsuma-no-imouto",
      "__v": 2,
      "chapter_index": 1,
      "createdAt": "2025-12-02T06:52:22.647Z",
      "images": [
        "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (1).webp",
        "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (2).webp",
        "https://cdn.manhwature.com/desu.photos/uploads/DOUJINSHI/Tsuma no Imouto/5 (3).webp"
      ],
      "link": "https://doujindesu.tv/tsuma-no-imouto/",
      "title": "1",
      "updatedAt": "2025-12-27T19:41:44.694Z",
      "sql_id": 774
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

**Response Fields**:
- `success` (boolean): Request status
- `data.chapter` (object): Chapter information
  - `_id` (string): Chapter MongoDB ObjectId
  - `manga_id` (string): Parent manga ObjectId
  - `slug` (string): Chapter slug
  - `chapter_index` (number): Chapter number
  - `title` (string): Chapter title
  - `images` (array): Array of image URLs
  - `link` (string): Original source link
  - `createdAt` (string): ISO datetime
  - `updatedAt` (string): ISO datetime
- `data.manga` (object): Parent manga info
  - `_id` (string): Manga ObjectId
  - `slug` (string): Manga slug
  - `title` (string): Manga title
  - `thumb` (string): Thumbnail URL
- `data.navigation` (object): Chapter navigation
  - `next` (string|null): Next chapter slug
  - `prev` (string|null): Previous chapter slug

---

### 3. Search Manga

Mencari manga berdasarkan query string.

**Endpoint**: `GET /api/search?q={query}`

**Parameters**:
- `q` (string, required): Search query

**Example Request**:
```http
GET https://v2.doujindesu.fun/api/search?q=naruto
Accept: application/json
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
```

**Example Response**:
```json
{
  "success": true,
  "data": [
    {
      "_id": "69304f990cc971443a671cb8",
      "slug": "narutop-106",
      "metadata": {
        "status": "Finished",
        "type": "Doujinshi",
        "series": "Naruto",
        "author": "Sahara Wataru",
        "rating": "7.90",
        "created": "Kamis, 02 Oktober 2025"
      },
      "thumb": "https://cdn-images.doujindesu.fun/covers/narutop-106.jpg",
      "title": "NARUTOP 106",
      "chapter_count": 1
    },
    {
      "_id": "6950b23967a31c9f38387df0",
      "slug": "narutop-pink",
      "metadata": {
        "status": "Finished",
        "type": "Doujinshi",
        "series": "Naruto",
        "author": "Sahara Wataru",
        "rating": "7.90",
        "created": "Selasa, 22 Oktober 2024"
      },
      "thumb": "https://cdn-images.doujindesu.fun/covers/narutop-pink.gif",
      "title": "NARUTOP PINK",
      "chapter_count": 2
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 1,
    "totalItems": 4,
    "perPage": 24
  }
}
```

**Response Fields**:
- `success` (boolean): Request status
- `data` (array): Array of manga results
  - `_id` (string): MongoDB ObjectId
  - `slug` (string): Manga slug
  - `title` (string): Manga title
  - `thumb` (string): Thumbnail URL
  - `metadata` (object): Metadata
    - `status` (string): Publishing status
    - `type` (string): Content type
    - `series` (string): Series name
    - `author` (string): Author name
    - `rating` (string): Rating (0-10)
    - `created` (string): Creation date
  - `chapter_count` (number): Total chapters
- `pagination` (object): Pagination info
  - `currentPage` (number): Current page
  - `totalPages` (number): Total pages
  - `totalItems` (number): Total results
  - `perPage` (number): Results per page

---

## Data Models

### MangaListResult Model

```dart
class MangaListResult {
  final bool success;
  final List<MangaListItem> data;
  final Pagination pagination;

  MangaListResult({
    required this.success,
    required this.data,
    required this.pagination,
  });

  factory MangaListResult.fromJson(Map<String, dynamic> json) {
    return MangaListResult(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>)
          .map((e) => MangaListItem.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}
```

### MangaListItem Model

```dart
class MangaListItem {
  final String id;
  final String slug;
  final String title;
  final String thumb;
  final MangaMetadata metadata;
  final List<String> tags;
  final int views;
  final int chapterCount;
  final DateTime updatedAt;
  final LastChapter? lastChapter;

  MangaListItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.thumb,
    required this.metadata,
    required this.tags,
    required this.views,
    required this.chapterCount,
    required this.updatedAt,
    this.lastChapter,
  });

  factory MangaListItem.fromJson(Map<String, dynamic> json) {
    return MangaListItem(
      id: json['_id'],
      slug: json['slug'],
      title: json['title'],
      thumb: json['thumb'],
      metadata: MangaMetadata.fromJson(json['metadata']),
      tags: List<String>.from(json['tags'] ?? []),
      views: json['views'] ?? 0,
      chapterCount: json['chapter_count'] ?? 0,
      updatedAt: DateTime.parse(json['updatedAt']),
      lastChapter: json['last_chapter'] != null
          ? LastChapter.fromJson(json['last_chapter'])
          : null,
    );
  }
}
```

### LastChapter Model

```dart
class LastChapter {
  final String title;
  final String slug;
  final int chapterIndex;
  final DateTime createdAt;

  LastChapter({
    required this.title,
    required this.slug,
    required this.chapterIndex,
    required this.createdAt,
  });

  factory LastChapter.fromJson(Map<String, dynamic> json) {
    return LastChapter(
      title: json['title'],
      slug: json['slug'],
      chapterIndex: json['chapter_index'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

### SearchResult Model

```dart
class SearchResult {
  final String id;
  final String slug;
  final String title;
  final String thumb;
  final MangaMetadata metadata;
  final int chapterCount;

  SearchResult({
    required this.id,
    required this.slug,
    required this.title,
    required this.thumb,
    required this.metadata,
    required this.chapterCount,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['_id'],
      slug: json['slug'],
      title: json['title'],
      thumb: json['thumb'],
      metadata: MangaMetadata.fromJson(json['metadata']),
      chapterCount: json['chapter_count'] ?? 0,
    );
  }
}
```

### Pagination Model

```dart
class Pagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int perPage;

  Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.perPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      perPage: json['perPage'] ?? 24,
    );
  }
}
```

### MangaInfo Model

```dart
class MangaInfo {
  final String id;
  final String slug;
  final String title;
  final String? alternativeTitle;
  final String thumb;
  final MangaMetadata metadata;
  final String synopsis;
  final List<String> tags;
  final int views;
  final int chapterCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  MangaInfo({
    required this.id,
    required this.slug,
    required this.title,
    this.alternativeTitle,
    required this.thumb,
    required this.metadata,
    required this.synopsis,
    required this.tags,
    required this.views,
    required this.chapterCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MangaInfo.fromJson(Map<String, dynamic> json) {
    return MangaInfo(
      id: json['_id'],
      slug: json['slug'],
      title: json['title'],
      alternativeTitle: json['alternativeTitle'],
      thumb: json['thumb'],
      metadata: MangaMetadata.fromJson(json['metadata']),
      synopsis: json['synopsis'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      views: json['views'] ?? 0,
      chapterCount: json['chapter_count'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
```

### MangaMetadata Model

```dart
class MangaMetadata {
  final String status;
  final String type;
  final String series;
  final String author;
  final String rating;
  final String created;

  MangaMetadata({
    required this.status,
    required this.type,
    required this.series,
    required this.author,
    required this.rating,
    required this.created,
  });

  factory MangaMetadata.fromJson(Map<String, dynamic> json) {
    return MangaMetadata(
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      series: json['series'] ?? '',
      author: json['author'] ?? '',
      rating: json['rating'] ?? '0',
      created: json['created'] ?? '',
    );
  }
}
```

### Chapter Model

```dart
class Chapter {
  final String id;
  final String slug;
  final int chapterIndex;
  final String title;
  final DateTime createdAt;

  Chapter({
    required this.id,
    required this.slug,
    required this.chapterIndex,
    required this.title,
    required this.createdAt,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['_id'],
      slug: json['slug'],
      chapterIndex: json['chapter_index'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

### ChapterContent Model

```dart
class ChapterContent {
  final String id;
  final String mangaId;
  final String slug;
  final int chapterIndex;
  final String title;
  final List<String> images;
  final String? link;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChapterContent({
    required this.id,
    required this.mangaId,
    required this.slug,
    required this.chapterIndex,
    required this.title,
    required this.images,
    this.link,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    return ChapterContent(
      id: json['_id'],
      mangaId: json['manga_id'],
      slug: json['slug'],
      chapterIndex: json['chapter_index'],
      title: json['title'],
      images: List<String>.from(json['images']),
      link: json['link'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
```

---

## Error Handling

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Manga not found"
  }
}
```

### Common Error Codes

| Status Code | Error Code | Description |
|-------------|------------|-------------|
| 404 | NOT_FOUND | Resource not found |
| 429 | RATE_LIMIT_EXCEEDED | Too many requests |
| 500 | INTERNAL_ERROR | Server error |
| 503 | SERVICE_UNAVAILABLE | Service temporarily unavailable |

### Error Handling Example

```dart
Future<MangaInfo> getMangaDetail(String slug) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/manga/$slug'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return MangaInfo.fromJson(json['data']['info']);
      } else {
        throw ApiException(json['error']['message']);
      }
    } else if (response.statusCode == 404) {
      throw NotFoundException('Manga not found');
    } else if (response.statusCode == 429) {
      throw RateLimitException('Rate limit exceeded');
    } else {
      throw ServerException('Server error: ${response.statusCode}');
    }
  } catch (e) {
    throw NetworkException('Network error: $e');
  }
}
```

---

## Rate Limiting

### Recommendations

- **Max Requests**: 30 requests per minute
- **Min Delay**: 2000ms between requests
- **Cooldown**: 10 minutes after 429 error
- **Retry**: 3 attempts with exponential backoff

### Rate Limiter Implementation

```dart
class RateLimiter {
  final int requestsPerMinute;
  final Duration minDelay;
  DateTime? _lastRequestTime;
  int _requestCount = 0;
  DateTime? _windowStart;

  RateLimiter({
    this.requestsPerMinute = 30,
    this.minDelay = const Duration(milliseconds: 2000),
  });

  Future<void> waitIfNeeded() async {
    final now = DateTime.now();

    // Reset window if needed
    if (_windowStart == null || 
        now.difference(_windowStart!).inMinutes >= 1) {
      _windowStart = now;
      _requestCount = 0;
    }

    // Check rate limit
    if (_requestCount >= requestsPerMinute) {
      final waitTime = Duration(minutes: 1) - 
                      now.difference(_windowStart!);
      await Future.delayed(waitTime);
      _windowStart = DateTime.now();
      _requestCount = 0;
    }

    // Enforce minimum delay
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = now.difference(_lastRequestTime!);
      if (timeSinceLastRequest < minDelay) {
        await Future.delayed(minDelay - timeSinceLastRequest);
      }
    }

    _lastRequestTime = DateTime.now();
    _requestCount++;
  }
}
```

---

## Code Examples

### Complete Data Source Implementation

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class DoujinDesuV2DataSource {
  static const String baseUrl = 'https://v2.doujindesu.fun';
  static const String apiBaseUrl = '$baseUrl/api';
  
  final http.Client httpClient;
  final RateLimiter rateLimiter;

  DoujinDesuV2DataSource({
    required this.httpClient,
    required this.rateLimiter,
  });

  Future<MangaDetail> getMangaDetail(String slug) async {
    await rateLimiter.waitIfNeeded();
    
    final response = await _retryRequest(() async {
      return await httpClient.get(
        Uri.parse('$apiBaseUrl/manga/$slug'),
        headers: _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return MangaDetail.fromJson(json['data']);
    } else {
      throw _handleError(response);
    }
  }

  Future<MangaListResult> getMangaList({
    String? query,
    int limit = 24,
    int page = 1,
  }) async {
    await rateLimiter.waitIfNeeded();
    
    var url = '$apiBaseUrl/manga-list?limit=$limit&page=$page';
    if (query != null && query.isNotEmpty) {
      url += '&q=$query';
    }
    
    final response = await _retryRequest(() async {
      return await httpClient.get(
        Uri.parse(url),
        headers: _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return MangaListResult.fromJson(json);
    } else {
      throw _handleError(response);
    }
  }

  Future<List<SearchResult>> searchManga(String query) async {
    await rateLimiter.waitIfNeeded();
    
    final response = await _retryRequest(() async {
      return await httpClient.get(
        Uri.parse('$apiBaseUrl/search?q=$query'),
        headers: _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> data = json['data'] ?? [];
      return data.map((e) => SearchResult.fromJson(e)).toList();
    } else {
      throw _handleError(response);
    }
  }

  Future<ChapterRead> getChapterContent(
    String mangaSlug,
    String chapterSlug,
  ) async {
    await rateLimiter.waitIfNeeded();
    
    final response = await _retryRequest(() async {
      return await httpClient.get(
        Uri.parse('$apiBaseUrl/read/$mangaSlug/$chapterSlug'),
        headers: _getHeaders(),
      );
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ChapterRead.fromJson(json['data']);
    } else {
      throw _handleError(response);
    }
  }

  Map<String, String> _getHeaders() => {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                  'AppleWebKit/537.36 (KHTML, like Gecko) '
                  'Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json',
    'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
    'Referer': baseUrl,
  };

  Future<http.Response> _retryRequest(
    Future<http.Response> Function() request, {
    int maxAttempts = 3,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      try {
        return await request();
      } catch (e) {
        if (i == maxAttempts - 1) rethrow;
        await Future.delayed(Duration(seconds: 3 * (i + 1)));
      }
    }
    throw Exception('Max retries exceeded');
  }

  Exception _handleError(http.Response response) {
    switch (response.statusCode) {
      case 404:
        return NotFoundException('Resource not found');
      case 429:
        return RateLimitException('Rate limit exceeded');
      case 500:
      case 503:
        return ServerException('Server error: ${response.statusCode}');
      default:
        return ApiException('API error: ${response.statusCode}');
    }
  }
}
```

### Usage Example

```dart
void main() async {
  final dataSource = DoujinDesuV2DataSource(
    httpClient: http.Client(),
    rateLimiter: RateLimiter(
      requestsPerMinute: 30,
      minDelay: Duration(milliseconds: 2000),
    ),
  );

  try {
    // Get manga list with pagination
    final mangaList = await dataSource.getMangaList(
      query: 'ne',
      limit: 8,
      page: 1,
    );
    print('Found ${mangaList.data.length} results');
    print('Total: ${mangaList.pagination.totalItems} items');
    print('Pages: ${mangaList.pagination.totalPages}');
    
    for (var manga in mangaList.data) {
      print('${manga.title} - ${manga.chapterCount} chapters');
      if (manga.lastChapter != null) {
        print('  Latest: ${manga.lastChapter!.title}');
      }
    }

    // Search manga
    final searchResults = await dataSource.searchManga('naruto');
    print('Found ${searchResults.length} search results');
    for (var result in searchResults) {
      print('${result.title} - ${result.chapterCount} chapters');
    }

    // Get manga detail
    if (mangaList.data.isNotEmpty) {
      final manga = await dataSource.getMangaDetail(mangaList.data.first.slug);
      print('Title: ${manga.info.title}');
      print('Chapters: ${manga.chapters.length}');

      // Get first chapter
      if (manga.chapters.isNotEmpty) {
        final chapter = await dataSource.getChapterContent(
          mangaList.data.first.slug,
          manga.chapters.first.slug,
        );
        print('Images: ${chapter.chapter.images.length}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## Summary of API Endpoints

| Endpoint | Method | Purpose | Pagination |
|----------|--------|---------|-----------|
| `/api/manga-list` | GET | Get paginated manga list | Yes |
| `/api/search` | GET | Search manga | Yes |
| `/api/manga/{slug}` | GET | Get manga detail | No |
| `/api/read/{slug}/{chapter}` | GET | Get chapter content | No |

## Query Parameters

### manga-list
- `q` (optional): Search query
- `limit` (optional): Results per page (default: 24)
- `page` (optional): Page number (default: 1)

### search
- `q` (required): Search query

### manga/{slug}
- No parameters

### read/{slug}/{chapter}
- No parameters

---

**Last Updated**: 2026-05-10  
**Maintained by**: Kuron App Development Team
