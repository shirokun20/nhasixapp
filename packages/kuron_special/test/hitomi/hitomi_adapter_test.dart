import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kuron_core/kuron_core.dart';
import 'package:kuron_special/src/hitomi/hitomi_adapter.dart';
import 'package:kuron_special/src/hitomi/hitomi_source_factory.dart';
import 'package:logger/logger.dart';

void main() {
  group('HitomiAdapter', () {
    late Dio dio;
    late DioAdapter mock;
    late HitomiAdapter adapter;

    const config = {
      'source': 'hitomi',
      'baseUrl': 'https://hitomi.la',
      'network': {
        'headers': {
          'User-Agent': 'Mozilla/5.0 Unit Test',
        },
      },
      'hitomiProtocol': {
        'indexNozomiEndpoint':
            'https://ltn.gold-usergeneratedcontent.net/index-all.nozomi',
        'searchNozomiEndpoint':
            'https://ltn.gold-usergeneratedcontent.net/search/{hash}-all.nozomi',
        'tagNozomiEndpoint':
            'https://ltn.gold-usergeneratedcontent.net/tag/{query}-all.nozomi',
        'galleryJsEndpoint':
            'https://ltn.gold-usergeneratedcontent.net/galleries/{id}.js',
        'ggJsEndpoint': 'https://ltn.gold-usergeneratedcontent.net/gg.js',
      },
    };

    setUp(() {
      dio = Dio();
      mock = DioAdapter(dio: dio);
      adapter = HitomiAdapter(dio: dio, logger: Logger());
    });

    void mockGg() {
      mock.onGet(
        'https://ltn.gold-usergeneratedcontent.net/gg.js',
        (server) => server.reply(200,
            "var o = 1; switch(x){case 42:o = 2; break;} m = {b: 'abc/'};"),
      );
    }

    void mockNozomi({
      required String url,
      required List<int> ids,
    }) {
      mock.onGet(
        url,
        (server) => server.reply(200, _encodeNozomi(ids)),
      );
    }

    void mockGallery({
      required int id,
      required String title,
      required List<_HitomiFile> files,
      List<int> related = const [],
    }) {
      final fileJson =
          files.map((f) => '{"hash":"${f.hash}","name":"${f.name}"}').join(',');
      final relatedJson = related.map((e) => e.toString()).join(',');

      mock.onGet(
        'https://ltn.gold-usergeneratedcontent.net/galleries/$id.js',
        (server) => server.reply(
          200,
          '''var galleryinfo = {
            "id":"$id",
            "title":"$title",
            "galleryurl":"/doujinshi/sample-$id.html",
            "date":"2026-03-23 09:09:00-05",
            "language":"english",
            "files":[$fileJson],
            "related":[$relatedJson],
            "tags":[{"tag":"anal","female":"1","male":""}],
            "artists":[],
            "characters":[],
            "parodys":[],
            "groups":[]
          };''',
        ),
      );
    }

    test('search pagination works for page 1 and page 2', () async {
      final ids = List<int>.generate(25, (i) => i + 1);
      mockNozomi(
        url: 'https://ltn.gold-usergeneratedcontent.net/index-all.nozomi',
        ids: ids,
      );
      mockGg();
      for (final id in ids) {
        mockGallery(
          id: id,
          title: 'Sample Hitomi $id',
          files: const [
            _HitomiFile(
              hash:
                  'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
              name: '01.webp',
            ),
          ],
        );
      }

      final page1 = await adapter.search(const SearchFilter(page: 1), config);
      final page2 = await adapter.search(const SearchFilter(page: 2), config);

      expect(page1.items.length, 20);
      expect(page1.hasNextPage, isTrue);
      expect(page1.totalPages, 2);
      expect(page1.totalItems, 25);

      expect(page2.items.length, 5);
      expect(page2.hasNextPage, isFalse);
      expect(page2.totalPages, 2);
      expect(page2.totalItems, 25);
    });

    test('query search uses tag nozomi endpoint', () async {
      mockNozomi(
        url:
            'https://ltn.gold-usergeneratedcontent.net/tag/female%3Aanal-all.nozomi',
        ids: const [11, 12],
      );
      mockGg();
      mockGallery(id: 11, title: 'Query 11', files: const [_sampleFile]);
      mockGallery(id: 12, title: 'Query 12', files: const [_sampleFile]);

      final result = await adapter.search(
        const SearchFilter(query: 'female:anal', page: 1),
        config,
      );

      expect(result.items.length, 2);
      expect(result.items.first.id, '11');
    });

    test('home list pagination works via source.getList', () async {
      final source = HitomiSourceFactory(dio: dio, logger: Logger())
          .create(Map<String, dynamic>.from(config));

      final ids = List<int>.generate(22, (i) => i + 1);
      mockNozomi(
        url: 'https://ltn.gold-usergeneratedcontent.net/index-all.nozomi',
        ids: ids,
      );
      mockGg();
      for (final id in ids) {
        mockGallery(id: id, title: 'List $id', files: const [_sampleFile]);
      }

      final listPage1 = await source.getList(page: 1);
      final listPage2 = await source.getList(page: 2);

      expect(listPage1.contents.length, 20);
      expect(listPage1.hasNext, isTrue);

      expect(listPage2.contents.length, 2);
      expect(listPage2.hasNext, isFalse);
    });

    test('detail after search returns complete reader image URLs', () async {
      mockNozomi(
        url: 'https://ltn.gold-usergeneratedcontent.net/index-all.nozomi',
        ids: const [1],
      );
      mockGg();
      mockGallery(
        id: 1,
        title: 'Sample Hitomi',
        files: const [
          _HitomiFile(
            hash:
                '1111111111111111111111111111111111111111111111111111111111111111',
            name: '01.webp',
          ),
          _HitomiFile(
            hash:
                '2222222222222222222222222222222222222222222222222222222222222222',
            name: '02.webp',
          ),
          _HitomiFile(
            hash:
                '3333333333333333333333333333333333333333333333333333333333333333',
            name: '03.webp',
          ),
        ],
      );

      final search = await adapter.search(const SearchFilter(page: 1), config);
      final selectedId = search.items.first.id;
      final detail = await adapter.fetchDetail(selectedId, config);

      expect(detail.content.id, selectedId);
      expect(detail.content.coverUrl, isNotEmpty);
      expect(detail.imageUrls.length, 3);
      expect(detail.imageUrls.first, startsWith('https://'));
      expect(detail.imageUrls[1], startsWith('https://'));
      expect(detail.imageUrls.last, startsWith('https://'));
      expect(detail.content.chapters, isNull);
    });

    test(
        'related is returned while comments/chapter stay empty for non-chapter',
        () async {
      mockGg();
      mockGallery(
        id: 1,
        title: 'Primary',
        files: const [_sampleFile],
        related: const [2],
      );
      mockGallery(
        id: 2,
        title: 'Related Item',
        files: const [_sampleFile],
      );

      final related = await adapter.fetchRelated('1', config);
      final comments = await adapter.fetchComments('1', config);
      final chapter = await adapter.fetchChapterImages('1', config);

      expect(related.length, 1);
      expect(related.first.id, '2');
      expect(comments, isEmpty);
      expect(chapter, isNull);
    });

    test('source image download headers include referer and user agent',
        () async {
      final source = HitomiSourceFactory(dio: dio, logger: Logger())
          .create(Map<String, dynamic>.from(config));

      final headers = source.getImageDownloadHeaders(
        imageUrl:
            'https://w2.gold-usergeneratedcontent.net/123/456/sample.webp',
      );

      expect(headers['Referer'], 'https://hitomi.la/');
      expect(headers['User-Agent'], 'Mozilla/5.0 Unit Test');
    });

    test('builds JSON evidence per screen contract', () async {
      final source = HitomiSourceFactory(dio: dio, logger: Logger())
          .create(Map<String, dynamic>.from(config));

      final ids = List<int>.generate(23, (i) => i + 1);
      mockNozomi(
        url: 'https://ltn.gold-usergeneratedcontent.net/index-all.nozomi',
        ids: ids,
      );
      mockNozomi(
        url:
            'https://ltn.gold-usergeneratedcontent.net/tag/female%3Aanal-all.nozomi',
        ids: const [11, 12, 13],
      );
      mockGg();

      for (final id in ids) {
        mockGallery(
          id: id,
          title: 'Screen $id',
          files: const [
            _HitomiFile(
              hash:
                  'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
              name: '01.webp',
            ),
          ],
        );
      }

      mockGallery(
        id: 99,
        title: 'Detail Screen',
        related: const [2],
        files: const [
          _HitomiFile(
            hash:
                '1111111111111111111111111111111111111111111111111111111111111111',
            name: '01.webp',
          ),
          _HitomiFile(
            hash:
                '2222222222222222222222222222222222222222222222222222222222222222',
            name: '02.webp',
          ),
          _HitomiFile(
            hash:
                '3333333333333333333333333333333333333333333333333333333333333333',
            name: '03.webp',
          ),
        ],
      );

      final homePage1 = await source.getList(page: 1);
      final homePage2 = await source.getList(page: 2);
      final searchPage1 = await source
          .search(const SearchFilter(query: 'female:anal', page: 1));

      final detail = await adapter.fetchDetail('99', config);
      final related = await adapter.fetchRelated('99', config);
      final comments = await adapter.fetchComments('99', config);
      final chapter = await adapter.fetchChapterImages('99', config);

      final evidence = <String, dynamic>{
        'sourceId': 'hitomi',
        'home': {
          'page1': {
            'currentPage': homePage1.currentPage,
            'count': homePage1.contents.length,
            'hasNext': homePage1.hasNext,
          },
          'page2': {
            'currentPage': homePage2.currentPage,
            'count': homePage2.contents.length,
            'hasNext': homePage2.hasNext,
          },
        },
        'search': {
          'page1': {
            'query': 'female:anal',
            'count': searchPage1.contents.length,
            'firstId': searchPage1.contents.isNotEmpty
                ? searchPage1.contents.first.id
                : '',
          },
        },
        'detail': {
          'contentId': detail.content.id,
          'title': detail.content.title,
          'coverUrl': detail.content.coverUrl,
          'pageCount': detail.imageUrls.length,
        },
        'related': {
          'count': related.length,
          'firstId': related.isNotEmpty ? related.first.id : '',
        },
        'comments': {
          'count': comments.length,
        },
        'reader': {
          'first': detail.imageUrls.isNotEmpty ? detail.imageUrls.first : '',
          'middle': detail.imageUrls.length > 1
              ? detail.imageUrls[detail.imageUrls.length ~/ 2]
              : (detail.imageUrls.isNotEmpty ? detail.imageUrls.first : ''),
          'last': detail.imageUrls.isNotEmpty ? detail.imageUrls.last : '',
        },
        'chapterData': {
          'returned': chapter != null,
        },
      };

      final encoded = const JsonEncoder.withIndent('  ').convert(evidence);

      expect(evidence['sourceId'], 'hitomi');
      expect(((evidence['home'] as Map)['page1'] as Map)['count'], 20);
      expect(((evidence['home'] as Map)['page2'] as Map)['count'], 3);
      expect(((evidence['search'] as Map)['page1'] as Map)['count'], 3);
      expect((evidence['detail'] as Map)['coverUrl'], isNotEmpty);
      expect((evidence['reader'] as Map)['first'], startsWith('https://'));
      expect((evidence['reader'] as Map)['middle'], startsWith('https://'));
      expect((evidence['reader'] as Map)['last'], startsWith('https://'));
      expect(((evidence['related'] as Map)['count'] as int),
          greaterThanOrEqualTo(1));
      expect(((evidence['comments'] as Map)['count'] as int), 0);
      expect(((evidence['chapterData'] as Map)['returned'] as bool), isFalse);

      expect(encoded, contains('"home"'));
      expect(encoded, contains('"search"'));
      expect(encoded, contains('"detail"'));
      expect(encoded, contains('"related"'));
      expect(encoded, contains('"comments"'));
      expect(encoded, contains('"reader"'));
    });

    test('normalizes raw-encoded query from DynamicFormSearchUI', () async {
      // When DynamicFormSearchUI submits with multi-field form, it encodes query as:
      // "raw:q=url_encoded_value&other_param=..."
      // HitomiAdapter must extract the plain tag from the q parameter
      mockNozomi(
        url:
            'https://ltn.gold-usergeneratedcontent.net/tag/female%3Aanal-all.nozomi',
        ids: const [10],
      );
      mockGg();
      mockGallery(id: 10, title: 'Search via raw', files: const [_sampleFile]);

      final result = await adapter.search(
        const SearchFilter(query: 'raw:q=female%3Aanal', page: 1),
        config,
      );

      expect(result.items.length, 1);
      expect(result.items.first.id, '10');
    });

    test('handles raw-encoded multi-field query with space-joined tokens',
        () async {
      // If config ever adds multi-field that join with spaces,
      // raw query might be: "raw:q=female%3Aanal&q=artist%3Aname"
      // Should handle multiple q params gracefully
      mockNozomi(
        url:
            'https://ltn.gold-usergeneratedcontent.net/tag/female%3Aanal%20artist%3Aname-all.nozomi',
        ids: const [11],
      );
      mockGg();
      mockGallery(id: 11, title: 'Multi-param', files: const [_sampleFile]);

      final result = await adapter.search(
        const SearchFilter(
            query: 'raw:q=female%3Aanal&q=artist%3Aname', page: 1),
        config,
      );

      expect(result.items.length, 1);
      expect(result.items.first.id, '11');
    });

    test('plain query uses hash search nozomi endpoint', () async {
      mockNozomi(
        url:
            'https://ltn.gold-usergeneratedcontent.net/search/016526330aaf250542e5acc9103d9f663a8a5bb00d1b8607a1b170b6d93d6401-all.nozomi',
        ids: const [12],
      );
      mockGg();
      mockGallery(id: 12, title: 'Plain query', files: const [_sampleFile]);

      final result = await adapter.search(
        const SearchFilter(query: 'neko', page: 1),
        config,
      );

      expect(result.items.length, 1);
      expect(result.items.first.id, '12');
    });
  });
}

Uint8List _encodeNozomi(List<int> ids) {
  final bytes = ByteData(ids.length * 4);
  for (var i = 0; i < ids.length; i++) {
    bytes.setUint32(i * 4, ids[i], Endian.big);
  }
  return bytes.buffer.asUint8List();
}

class _HitomiFile {
  final String hash;
  final String name;

  const _HitomiFile({
    required this.hash,
    required this.name,
  });
}

const _sampleFile = _HitomiFile(
  hash: 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
  name: '01.webp',
);
