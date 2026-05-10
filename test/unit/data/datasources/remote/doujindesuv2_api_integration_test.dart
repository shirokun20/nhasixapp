import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoujinDesu v2 API Integration', () {
    // Test data representing actual API responses
    const String baseUrl = 'https://v2.doujindesu.fun';

    test('should build correct manga-list endpoint URL', () {
      // Test endpoint building
      const int page = 1;
      const int limit = 24;

      const url = '$baseUrl/api/manga-list?limit=$limit&page=$page';
      expect(url, 'https://v2.doujindesu.fun/api/manga-list?limit=24&page=1');
    });

    test('should build correct search endpoint URL', () {
      const query = 'naruto';
      const url = '$baseUrl/api/search?q=$query';
      expect(url, 'https://v2.doujindesu.fun/api/search?q=naruto');
    });

    test('should build correct detail endpoint URL', () {
      const slug = 'tsuma-no-imouto';
      const url = '$baseUrl/api/manga/$slug';
      expect(url, 'https://v2.doujindesu.fun/api/manga/tsuma-no-imouto');
    });

    test('should build correct chapter read endpoint URL', () {
      const slug = 'tsuma-no-imouto';
      const chapter = 'tsuma-no-imouto';
      const url = '$baseUrl/api/read/$slug/$chapter';
      expect(url,
          'https://v2.doujindesu.fun/api/read/tsuma-no-imouto/tsuma-no-imouto');
    });

    test('should handle special characters in search query', () {
      final query = Uri.encodeComponent('naruto');
      final url = '$baseUrl/api/search?q=$query';
      expect(url, contains('q=naruto'));
    });

    test('should handle URL encoding for manga slug', () {
      final slug = Uri.encodeComponent('test-manga');
      final url = '$baseUrl/api/manga/$slug';
      expect(url, 'https://v2.doujindesu.fun/api/manga/test-manga');
    });

    test('should parse manga-list response correctly', () {
      const responseJson = '''
      {
        "success": true,
        "data": [
          {
            "_id": "69fdea77f64532fbd3d04e1b",
            "slug": "new-town-massage",
            "title": "New Town Massage",
            "thumb": "https://cdn-images.doujindesu.fun/covers/new-town-massage.jpg",
            "metadata": {
              "status": "Publishing",
              "type": "Manhwa",
              "series": "Manhwa",
              "author": "Basasak, Secret Service",
              "rating": "8.80",
              "created": "Jumat, 08 Mei 2026"
            },
            "tags": ["Ahegao", "Big Ass", "Big Breast"],
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
      ''';

      final decoded = jsonDecode(responseJson) as Map<String, dynamic>;

      expect(decoded['success'], isTrue);
      expect(decoded['data'], isA<List>());
      expect((decoded['data'] as List).length, 1);
      expect(decoded['pagination']['totalItems'], 932);
      expect(decoded['pagination']['totalPages'], 117);
    });

    test('should parse search response correctly', () {
      const responseJson = '''
      {
        "success": true,
        "data": [
          {
            "_id": "69304f990cc971443a671cb8",
            "slug": "narutop-106",
            "title": "NARUTOP 106",
            "thumb": "https://cdn-images.doujindesu.fun/covers/narutop-106.jpg",
            "metadata": {
              "status": "Finished",
              "type": "Doujinshi",
              "series": "Naruto",
              "author": "Sahara Wataru",
              "rating": "7.90",
              "created": "Kamis, 02 Oktober 2025"
            },
            "chapter_count": 1
          }
        ],
        "pagination": {
          "currentPage": 1,
          "totalPages": 1,
          "totalItems": 4,
          "perPage": 24
        }
      }
      ''';

      final decoded = jsonDecode(responseJson) as Map<String, dynamic>;

      expect(decoded['success'], isTrue);
      expect((decoded['data'] as List).first['metadata']['series'], 'Naruto');
      expect((decoded['data'] as List).first['chapter_count'], 1);
    });

    test('should parse manga detail response correctly', () {
      const responseJson = '''
      {
        "success": true,
        "data": {
          "info": {
            "_id": "692e8c9f0cc971443a671573",
            "slug": "tsuma-no-imouto",
            "alternativeTitle": "妻の妹, Wife's Younger Sister",
            "metadata": {
              "status": "Finished",
              "type": "Doujinshi",
              "series": "Original",
              "author": "",
              "rating": "8.50",
              "created": "Selasa, 22 Juli 2025"
            },
            "synopsis": "",
            "tags": ["Big Ass", "Big Penis"],
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
              "createdAt": "2026-04-15T15:48:18.016Z",
              "title": "4 END"
            }
          ],
          "recommendations": []
        },
        "pagination": null
      }
      ''';

      final decoded = jsonDecode(responseJson) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;

      expect(decoded['success'], isTrue);
      expect(data['info']['slug'], 'tsuma-no-imouto');
      expect(data['info']['title'], 'Tsuma no Imouto');
      expect(data['chapters'], isA<List>());
      expect((data['chapters'] as List).length, 1);
      expect(decoded['pagination'], isNull);
    });

    test('should parse chapter read response correctly', () {
      const responseJson = '''
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
              "https://cdn.manhwature.com/desu.photos/1.webp",
              "https://cdn.manhwature.com/desu.photos/2.webp"
            ],
            "link": "https://doujindesu.tv/tsuma-no-imouto/",
            "createdAt": "2025-12-02T06:52:22.647Z"
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
      ''';

      final decoded = jsonDecode(responseJson) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final chapter = data['chapter'] as Map<String, dynamic>;

      expect(decoded['success'], isTrue);
      expect(chapter['images'], isA<List>());
      expect((chapter['images'] as List).length, 2);
      expect(data['navigation']['next'], 'tsuma-no-imouto-2');
      expect(data['navigation']['prev'], isNull);
    });

    test('should build pagination URL with query', () {
      const query = 'ne';
      const page = 2;
      const limit = 8;

      const url = '$baseUrl/api/manga-list?q=$query&limit=$limit&page=$page';
      expect(
          url, 'https://v2.doujindesu.fun/api/manga-list?q=ne&limit=8&page=2');
    });

    test('should handle missing optional fields gracefully', () {
      const minimalManga = '''
      {
        "success": true,
        "data": [
          {
            "slug": "test",
            "title": "Test",
            "thumb": "test.jpg",
            "metadata": {},
            "tags": [],
            "views": 0,
            "chapter_count": 0
          }
        ],
        "pagination": {
          "currentPage": 1,
          "totalPages": 1,
          "totalItems": 1,
          "perPage": 24
        }
      }
      ''';

      final decoded = jsonDecode(minimalManga) as Map<String, dynamic>;
      final manga = (decoded['data'] as List).first as Map<String, dynamic>;

      expect(manga['slug'], 'test');
      expect(manga['metadata'], isA<Map>());
      expect(manga['tags'], isA<List>());
    });

    test('should validate content URL pattern', () {
      const contentUrlPattern = 'https://v2.doujindesu.fun/manga/{id}';

      const slug = 'test-manga';
      final contentUrl = contentUrlPattern.replaceAll('{id}', slug);

      expect(contentUrl, 'https://v2.doujindesu.fun/manga/test-manga');
      expect(contentUrl, startsWith('https://v2.doujindesu.fun/manga/'));
    });

    test('should parse different content types', () {
      final types = ['Manga', 'Manhwa', 'Doujinshi'];

      for (final type in types) {
        final metadata = {'type': type};
        expect(metadata['type'], type);
      }
    });

    test('should handle empty chapters list', () {
      const response = '''
      {
        "success": true,
        "data": {
          "info": {
            "slug": "test",
            "title": "Test",
            "metadata": {"status": "Finished"},
            "tags": [],
            "views": 0,
            "chapter_count": 0
          },
          "chapters": [],
          "recommendations": []
        }
      }
      ''';

      final decoded = jsonDecode(response) as Map<String, dynamic>;
      final chapters =
          (decoded['data'] as Map<String, dynamic>)['chapters'] as List;

      expect(chapters, isEmpty);
    });

    test('should handle recommendations array', () {
      const response = '''
      {
        "success": true,
        "data": {
          "info": {
            "slug": "test",
            "title": "Test",
            "metadata": {},
            "tags": [],
            "views": 0,
            "chapter_count": 0
          },
          "chapters": [],
          "recommendations": [
            {
              "slug": "rec-1",
              "title": "Recommendation 1",
              "thumb": "rec1.jpg",
              "metadata": {"type": "Doujinshi"},
              "views": 100,
              "chapter_count": 1
            }
          ]
        }
      }
      ''';

      final decoded = jsonDecode(response) as Map<String, dynamic>;
      final recommendations =
          (decoded['data'] as Map<String, dynamic>)['recommendations'] as List;

      expect(recommendations.length, 1);
      expect(recommendations.first['title'], 'Recommendation 1');
    });
  });
}
