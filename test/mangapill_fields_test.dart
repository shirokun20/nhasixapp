import 'dart:io';
import 'package:test/test.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as p;

void main() {
  test('mangapill card field extraction', () {
    final html = File('test/fixtures/mangapill_home.html').readAsStringSync();
    final doc = p.parse(html);

    final container = '.my-3.grid.justify-end.gap-3 > div';
    final cards = doc.querySelectorAll(container);
    debugPrint('Cards found: ${cards.length}');

    for (int i = 0; i < 3 && i < cards.length; i++) {
      final card = cards[i];
      debugPrint('\n--- Card $i ---');

      // ID: a[href^="/manga/"]
      final idEl = card.querySelector('a[href^="/manga/"]');
      debugPrint('ID href: ${idEl?.attributes['href']}');

      // Title: .mt-3.font-black.leading-tight.line-clamp-2
      final titleEl =
          card.querySelector('.mt-3.font-black.leading-tight.line-clamp-2');
      debugPrint('Title text: ${titleEl?.text.trim()}');

      // Cover: img.lazy.object-cover -> data-src
      final cover = card.querySelector('img.lazy.object-cover');
      if (cover != null) {
        debugPrint('Cover data-src: ${cover.attributes['data-src']}');
        debugPrint('Cover src: ${cover.attributes['src']}');
      }

      if (idEl == null || titleEl == null) {
        debugPrint('*** MISSING FIELDS ***');
        debugPrint('Card HTML: ${card.innerHtml.substring(0, 300)}');
      }
    }
  });
}
