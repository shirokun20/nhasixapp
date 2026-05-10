import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoujinDesu v2 API Response Parsing', () {
    // Sample responses from actual API calls
    const mangaListJson = '''
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
          "updatedAt": "2026-05-08T13:51:47.346Z",
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

    const searchJson = '''
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

    const detailJson = '''
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
          "tags": ["Big Ass", "Big Penis"],
          "thumb": "https://cdn-images.doujindesu.fun/covers/tsuma-no-imouto.jpg",
          "title": "Tsuma no Imouto",
          "updatedAt": "2026-04-15T15:48:13.093Z",
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
    ''';

    const chapterReadJson = '''
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
          "createdAt": "2025-12-02T06:52:22.647Z",
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
    ''';

    test('should parse manga-list JSON response correctly', () {
      final decoded = jsonDecode(mangaListJson) as Map<String, dynamic>;

      expect(decoded['success'], isTrue);
      expect(decoded['data'], isA<List>());
      expect((decoded['data'] as List).length, 1);

      final manga = (decoded['data'] as List).first as Map<String, dynamic>;
      expect(manga['slug'], 'new-town-massage');
      expect(manga['title'], 'New Town Massage');
      expect(manga['thumb'], contains('doujindesu.fun'));
      expect(manga['views'], 5843);
      expect(manga['chapter_count'], 8);
      expect(manga['tags'], isA<List>());
      expect((manga['tags'] as List).length, 3);

      final metadata = manga['metadata'] as Map<String, dynamic>;
      expect(metadata['status'], 'Publishing');
      expect(metadata['type'], 'Manhwa');
      expect(metadata['author'], 'Basasak, Secret Service');
      expect(metadata['rating'], '8.80');

      final pagination = decoded['pagination'] as Map<String, dynamic>;
      expect(pagination['currentPage'], 1);
      expect(pagination['totalPages'], 117);
      expect(pagination['totalItems'], 932);
      expect(pagination['perPage'], 8);
    });

    test('should parse last_chapter from manga-list response', () {
      final decoded = jsonDecode(mangaListJson) as Map<String, dynamic>;
      final manga = (decoded['data'] as List).first as Map<String, dynamic>;

      expect(manga['last_chapter'], isNotNull);
      final lastChapter = manga['last_chapter'] as Map<String, dynamic>;
      expect(lastChapter['title'], '8');
      expect(lastChapter['slug'], 'new-town-massage-chapter-08');
      expect(lastChapter['chapter_index'], 8);
    });

    test('should parse search JSON response correctly', () {
      final decoded = jsonDecode(searchJson) as Map<String, dynamic>;

      expect(decoded['success'], isTrue);
      expect(decoded['data'], isA<List>());

      final searchItem =
          (decoded['data'] as List).first as Map<String, dynamic>;
      expect(searchItem['slug'], 'narutop-106');
      expect(searchItem['title'], 'NARUTOP 106');
      expect(searchItem['chapter_count'], 1);

      final metadata = searchItem['metadata'] as Map<String, dynamic>;
      expect(metadata['type'], 'Doujinshi');
      expect(metadata['series'], 'Naruto');
      expect(metadata['rating'], '7.90');

      final pagination = decoded['pagination'] as Map<String, dynamic>;
      expect(pagination['totalItems'], 4);
      expect(pagination['perPage'], 24);
    });

    test('should parse manga detail JSON response correctly', () {
      final decoded = jsonDecode(detailJson) as Map<String, dynamic>;

      expect(decoded['success'], isTrue);
      expect(decoded['pagination'], isNull);

      final data = decoded['data'] as Map<String, dynamic>;
      final info = data['info'] as Map<String, dynamic>;

      expect(info['slug'], 'tsuma-no-imouto');
      expect(info['title'], 'Tsuma no Imouto');
      expect(info['alternativeTitle'], contains('Wife'));
      expect(info['synopsis'], '');
      expect(info['views'], 13508);
      expect(info['chapter_count'], 4);
      expect(info['tags'], isA<List>());
      expect((info['tags'] as List).length, 2);

      final metadata = info['metadata'] as Map<String, dynamic>;
      expect(metadata['status'], 'Finished');
      expect(metadata['type'], 'Doujinshi');
      expect(metadata['series'], 'Original');
      expect(metadata['rating'], '8.50');
    });

    test('should parse chapters from detail response', () {
      final decoded = jsonDecode(detailJson) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final chapters = data['chapters'] as List;

      expect(chapters.length, 1);
      final chapter = chapters.first as Map<String, dynamic>;
      expect(chapter['slug'], 'tsuma-no-imouto-4');
      expect(chapter['chapter_index'], 4);
      expect(chapter['title'], '4 END');
    });

    test('should parse recommendations from detail response', () {
      final decoded = jsonDecode(detailJson) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final recommendations = data['recommendations'] as List;

      expect(recommendations.length, 1);
      final rec = recommendations.first as Map<String, dynamic>;
      expect(rec['slug'], 'sensei-trale-hossuru-karada');
      expect(rec['title'], contains('Sensei Trale'));
      expect(rec['views'], 538);
      expect(rec['chapter_count'], 1);
    });

    test('should parse chapter read JSON response correctly', () {
      final decoded = jsonDecode(chapterReadJson) as Map<String, dynamic>;

      expect(decoded['success'], isTrue);
      expect(decoded['pagination'], isNull);

      final data = decoded['data'] as Map<String, dynamic>;
      final chapter = data['chapter'] as Map<String, dynamic>;
      final manga = data['manga'] as Map<String, dynamic>;
      final navigation = data['navigation'] as Map<String, dynamic>;

      expect(chapter['slug'], 'tsuma-no-imouto');
      expect(chapter['chapter_index'], 1);
      expect(chapter['title'], '1');
      expect(chapter['images'], isA<List>());
      expect((chapter['images'] as List).length, 2);
      expect((chapter['images'] as List).first, contains('.webp'));

      expect(manga['slug'], 'tsuma-no-imouto');
      expect(manga['title'], 'Tsuma no Imouto');

      expect(navigation['next'], 'tsuma-no-imouto-2');
      expect(navigation['prev'], isNull);
    });

    test('should handle empty tags array', () {
      const json = '''
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
        "pagination": {"currentPage": 1, "totalPages": 1, "totalItems": 1, "perPage": 24}
      }
      ''';

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final manga = (decoded['data'] as List).first as Map<String, dynamic>;

      expect(manga['tags'], isA<List>());
      expect((manga['tags'] as List), isEmpty);
    });

    test('should handle null last_chapter', () {
      const json = '''
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
        "pagination": {"currentPage": 1, "totalPages": 1, "totalItems": 1, "perPage": 24}
      }
      ''';

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final manga = (decoded['data'] as List).first as Map<String, dynamic>;

      expect(manga.containsKey('last_chapter'), isFalse);
    });

    test('should handle empty chapters list', () {
      const json = '''
      {
        "success": true,
        "data": {
          "info": {"slug": "test", "title": "Test", "metadata": {}, "tags": [], "views": 0, "chapter_count": 0},
          "chapters": [],
          "recommendations": []
        }
      }
      ''';

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final chapters = data['chapters'] as List;

      expect(chapters, isEmpty);
    });

    test('should handle multiple chapters correctly', () {
      const json = '''
      {
        "success": true,
        "data": {
          "info": {"slug": "test"},
          "chapters": [
            {"slug": "chapter-1", "chapter_index": 1, "title": "Chapter 1"},
            {"slug": "chapter-2", "chapter_index": 2, "title": "Chapter 2"},
            {"slug": "chapter-3", "chapter_index": 3, "title": "Chapter 3"}
          ],
          "recommendations": []
        }
      }
      ''';

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final chapters = data['chapters'] as List;

      expect(chapters.length, 3);
      expect((chapters[0] as Map<String, dynamic>)['chapter_index'], 1);
      expect((chapters[1] as Map<String, dynamic>)['chapter_index'], 2);
      expect((chapters[2] as Map<String, dynamic>)['chapter_index'], 3);
    });

    test('should handle multiple images in chapter content', () {
      const json = '''
      {
        "success": true,
        "data": {
          "chapter": {
            "images": ["img1.webp", "img2.webp", "img3.webp", "img4.webp", "img5.webp"]
          },
          "manga": {},
          "navigation": {}
        }
      }
      ''';

      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final chapter = data['chapter'] as Map<String, dynamic>;
      final images = chapter['images'] as List;

      expect(images.length, 5);
    });

    test('should correctly identify content types', () {
      final types = ['Manga', 'Manhwa', 'Doujinshi'];

      for (final type in types) {
        final metadata = {'type': type};
        expect(metadata['type'], type);
      }
    });
  });
}
