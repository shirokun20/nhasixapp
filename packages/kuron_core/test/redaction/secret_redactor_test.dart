import 'package:kuron_core/kuron_core.dart';
import 'package:test/test.dart';

void main() {
  group('SecretRedactor.redactHeaders', () {
    test('redacts known sensitive header values regardless of case', () {
      final Map<String, String> headers = <String, String>{
        'Cookie': 'session=abc123',
        'cookie': 'sid=zzz',
        'Authorization': 'Bearer secret',
        'X-API-KEY': 'kkk',
        'Referer': 'https://example.com/',
        'User-Agent': 'TestAgent/1.0',
      };

      final Map<String, String> out = SecretRedactor.redactHeaders(headers);

      expect(out['Cookie'], SecretRedactor.placeholder);
      expect(out['cookie'], SecretRedactor.placeholder);
      expect(out['Authorization'], SecretRedactor.placeholder);
      expect(out['X-API-KEY'], SecretRedactor.placeholder);
      expect(out['Referer'], 'https://example.com/');
      expect(out['User-Agent'], 'TestAgent/1.0');
    });

    test('leaves empty values untouched', () {
      final Map<String, String> headers = <String, String>{
        'Cookie': '',
        'Authorization': '',
      };
      final Map<String, String> out = SecretRedactor.redactHeaders(headers);
      expect(out['Cookie'], '');
      expect(out['Authorization'], '');
    });
  });

  group('SecretRedactor.redactUrl', () {
    test('redacts sensitive query params and keeps others', () {
      const String url =
          'https://api.example.com/v1/data?token=abc&user=alice&signature=xyz&page=2';
      final String out = SecretRedactor.redactUrl(url);
      final Uri uri = Uri.parse(out);
      expect(uri.queryParameters['token'], SecretRedactor.placeholder);
      expect(uri.queryParameters['signature'], SecretRedactor.placeholder);
      expect(uri.queryParameters['user'], 'alice');
      expect(uri.queryParameters['page'], '2');
    });

    test('returns input unchanged for non-URL strings', () {
      expect(SecretRedactor.redactUrl(''), '');
      expect(SecretRedactor.redactUrl('not a url'), 'not a url');
    });

    test('returns input unchanged when no query', () {
      const String url = 'https://example.com/path/to/thing';
      expect(SecretRedactor.redactUrl(url), url);
    });
  });

  group('SecretRedactor.redactJson', () {
    test('redacts sensitive keys at any depth', () {
      final Map<String, Object?> input = <String, Object?>{
        'sourceId': 'nhentai',
        'session_id': 'aaa',
        'nested': <String, Object?>{
          'token': 'xyz',
          'public': 'hello',
          'deeper': <String, Object?>{
            'cookies': <String, String>{'sid': 'zzz'},
            'apiKey': 'kkk',
          },
        },
        'list': <Object?>[
          <String, Object?>{'password': 'p1', 'name': 'a'},
          <String, Object?>{'name': 'b'},
        ],
      };

      final Map<String, Object?> out = SecretRedactor.redactJson(input);

      expect(out['sourceId'], 'nhentai');
      expect(out['session_id'], SecretRedactor.placeholder);
      final Map<String, Object?> nested =
          out['nested']! as Map<String, Object?>;
      expect(nested['token'], SecretRedactor.placeholder);
      expect(nested['public'], 'hello');
      final Map<String, Object?> deeper =
          nested['deeper']! as Map<String, Object?>;
      expect(deeper['apiKey'], SecretRedactor.placeholder);
      final Map<String, Object?> cookies =
          deeper['cookies']! as Map<String, Object?>;
      expect(cookies['sid'], SecretRedactor.placeholder);
      final List<Object?> list = out['list']! as List<Object?>;
      final Map<String, Object?> first = list[0]! as Map<String, Object?>;
      final Map<String, Object?> second = list[1]! as Map<String, Object?>;
      expect(first['password'], SecretRedactor.placeholder);
      expect(first['name'], 'a');
      expect(second['name'], 'b');
    });

    test('redacts URL query params inside string values', () {
      final Map<String, Object?> input = <String, Object?>{
        'endpoint': 'https://api.example.com/x?token=secret&page=1',
      };
      final Map<String, Object?> out = SecretRedactor.redactJson(input);
      final String endpoint = out['endpoint']! as String;
      final Uri parsed = Uri.parse(endpoint);
      // Uri.replace URL-encodes the placeholder; compare on decoded params.
      expect(parsed.queryParameters['token'], SecretRedactor.placeholder);
      expect(parsed.queryParameters['page'], '1');
      expect(endpoint, isNot(contains('secret')));
    });
  });
}
