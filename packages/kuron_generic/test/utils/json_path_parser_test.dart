import 'dart:convert';
import 'package:test/test.dart';
import 'package:kuron_generic/src/models/source_config_runtime.dart';
import 'package:kuron_generic/src/parsers/generic_json_parser.dart';
import 'package:logger/logger.dart';

void main() {
  test('extractItems should return List of Maps', () {
    final data = jsonDecode('''
    {
      "result": "ok",
      "data": [
        {
          "id": "chap1",
          "attributes": {
            "chapter": "1",
            "readableAt": "2024-01-01T00:00:00+00:00"
          }
        },
        {
          "id": "chap2",
          "attributes": {
            "chapter": "2",
            "readableAt": "2024-01-02T00:00:00+00:00"
          }
        }
      ]
    }
    ''');

    final parser = GenericJsonParser(logger: Logger());
    final items =
        parser.extractItems(data, const FieldSelector(selector: '\$.data[*]'));

    expect(items.length, 2);
    expect(items.first['id'], 'chap1');
    expect(items.last['id'], 'chap2');
  });
}
