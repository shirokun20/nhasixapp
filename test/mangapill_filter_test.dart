import 'dart:io';
import 'package:test/test.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as p;

void main() {
  test('section filter analysis - all cards', () {
    final html = File('test/fixtures/mangapill_home.html').readAsStringSync();
    final doc = p.parse(html);
    final container = '.my-3.grid.justify-end.gap-3 > div';
    final cards = doc.querySelectorAll(container);
    debugPrint('Total cards: ${cards.length}');

    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      final titleEl =
          card.querySelector('.mt-3.font-black.leading-tight.line-clamp-2');
      final title = titleEl?.text.trim() ?? '(no title)';
      final idEl = card.querySelector('a[href^="/manga/"]');
      final id = idEl?.attributes['href'] ?? '(no id)';

      // sectionFilter DOM traversal
      final el = card;
      final sectionTitle = el.parent?.parent?.previousElementSibling?.text
              .trim()
              .toLowerCase() ??
          '';

      debugPrint('card[$i] section="$sectionTitle" title="$title" id=$id');
    }
  });
}
