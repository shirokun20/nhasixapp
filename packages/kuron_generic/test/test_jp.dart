import 'dart:convert';
import 'package:json_path/json_path.dart';
import 'package:test/test.dart';

void main() {
  test('json_path wildcard', () {
    final json = r'''
    {"thumbnails":{"base":"https://cdn.tld/foo","entries":[{"path":"/a/1.jpg","dimensions":[320,448]},{"path":"/b/2.jpg","dimensions":[320,448]}]}}
    ''';

    final data = jsonDecode(json);

    // Test wildcard
    final p1 = JsonPath(r'$.thumbnails.entries[*].path');
    final r1 = p1.read(data);
    final paths = r1.map((m) => m.value).toList();
    expect(paths.length, equals(2));
    expect(paths[0], equals('/a/1.jpg'));

    // Test manual
    final entries = data['thumbnails']['entries'] as List;
    final base = data['thumbnails']['base'] as String;
    final urls = entries.map((e) => '$base${e['path']}').toList();
    expect(urls.length, equals(2));
  });
}
