import 'dart:io';
import 'package:test/test.dart';
import 'package:html/parser.dart' as p;

void main() {
  test('genre search card extraction', () {
    final html = File('test/fixtures/mangapill_genre_ecchi.html').readAsStringSync();
    final doc = p.parse(html);

    // Container
    final container = '.grid.justify-end.gap-3 > div';
    final cards = doc.querySelectorAll(container);
    print('Cards in grid: ${cards.length}');

    // Check each card
    for (int i = 0; i < 3 && i < cards.length; i++) {
      final card = cards[i];
      final idEl = card.querySelector('a[href^="/manga/"]');
      final titleEl = card.querySelector('.mt-3.font-black.leading-tight.line-clamp-2');
      final cover = card.querySelector('img.lazy.object-cover');
      print('Card $i: id=${idEl?.attributes['href']} title=${titleEl?.text.trim()} cover=${cover?.attributes['data-src'] ?? cover?.attributes['src']}');
    }

    // Check pagination
    final prev = doc.querySelector('a.btn.btn-sm');
    print('Pagination link: ${prev?.text.trim()} href=${prev?.attributes['href']}');
    final allBtns = doc.querySelectorAll('a.btn.btn-sm');
    for (final b in allBtns) {
      print('  btn: "${b.text.trim()}" href="${b.attributes['href']}"');
    }
  });
}
