import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:test/test.dart';
import 'package:html/parser.dart' as p;

void main() {
  test('genre search card extraction', () {
    final html =
        File('test/fixtures/mangapill_genre_ecchi.html').readAsStringSync();
    final doc = p.parse(html);

    // Container
    final container = '.grid.justify-end.gap-3 > div';
    final cards = doc.querySelectorAll(container);
    debugPrint('Cards in grid: ${cards.length}');

    // Check each card
    for (int i = 0; i < 3 && i < cards.length; i++) {
      final card = cards[i];
      final idEl = card.querySelector('a[href^="/manga/"]');
      final titleEl =
          card.querySelector('.mt-3.font-black.leading-tight.line-clamp-2');
      final cover = card.querySelector('img.lazy.object-cover');
      debugPrint(
          'Card $i: id=${idEl?.attributes['href']} title=${titleEl?.text.trim()} cover=${cover?.attributes['data-src'] ?? cover?.attributes['src']}');
    }

    // Check pagination
    final prev = doc.querySelector('a.btn.btn-sm');
    debugPrint(
        'Pagination link: ${prev?.text.trim()} href=${prev?.attributes['href']}');
    final allBtns = doc.querySelectorAll('a.btn.btn-sm');
    for (final b in allBtns) {
      debugPrint('  btn: "${b.text.trim()}" href="${b.attributes['href']}"');
    }
  });
}
