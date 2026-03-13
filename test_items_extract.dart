import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:kuron_generic/src/parsers/generic_json_parser.dart';
import 'package:kuron_generic/src/mappers/generic_content_mapper.dart';
import 'package:kuron_generic/src/models/source_config_runtime.dart';

void main() {
  final data = jsonDecode('''{
    "result": "ok",
    "response": "collection",
    "data": [
      {
        "id": "a4d7c4fc-b411-4603-a0dd-ac34b7d4de18",
        "type": "manga",
        "attributes": {
          "title": {
            "ja-ro": "Katame no Majo-chan (Omake)"
          },
          "altTitles": [
            { "ja": "片眼の魔女ちゃん（おまけ）" },
            { "en": "One-Eyed Witch-chan (Special)" },
            { "pl": "Jednooka Wiedźma-chan (Special)" }
          ]
        }
      }
    ]
  }''');

  final parser = GenericJsonParser(logger: Logger());
  final items =
      parser.extractItems(data, const FieldSelector(selector: r'$.data[*]'));

  if (kDebugMode) {
    print('Found ${items.length} items');
  }
  if (items.isNotEmpty) {
    final item = items.first;
    if (kDebugMode) {
      print('Item type: ${item.runtimeType}');
    }

    const titleSelector = FieldSelector(selector: r'$.attributes.title');
    const altTitlesSelector =
        FieldSelector(selector: r'$.attributes.altTitles');

    final titleRaw = parser.extractRaw(item, titleSelector);
    final altTitlesRaw = parser.extractRaw(item, altTitlesSelector);

    if (kDebugMode) {
      print('Title raw (type ${titleRaw.runtimeType}): $titleRaw');
    }
    if (kDebugMode) {
      print('AltTitles raw (type ${altTitlesRaw.runtimeType}): $altTitlesRaw');
    }

    final fields = <String, dynamic>{
      'id': 'a4d7c4fc-b411-4603-a0dd-ac34b7d4de18',
      'title': titleRaw,
      'altTitles': altTitlesRaw,
      'tags': [],
    };

    final content =
        GenericContentMapper.toListItem(fields, sourceId: 'mangadex');
    if (kDebugMode) {
      print('Final Content Title: ${content.title}');
    }
  }
}
