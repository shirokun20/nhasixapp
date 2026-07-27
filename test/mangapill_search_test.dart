import 'dart:io';
import 'package:test/test.dart';
import 'package:html/parser.dart' as p;

void main() {
  test('mangapill search selectors', () {
    final html = File('test/fixtures/mangapill_search.html').readAsStringSync();
    final doc = p.parse(html);

    for (final el in doc.querySelectorAll('[class]')) {
      final cls = el.classes.join(' ');
      if (!cls.contains('grid-')) continue;
      final kids = el.children;
      final mangaLinks = el.querySelectorAll('a[href^="/manga/"]');
      if (mangaLinks.isNotEmpty) {
        print('"$cls" -> ${kids.length} children, ${mangaLinks.length} manga links');
      }
    }
  });
}
