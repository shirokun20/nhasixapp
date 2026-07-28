import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:test/test.dart';
import 'package:html/parser.dart' as p;

void main() {
  test('genre search pagination', () {
    final html =
        File('test/fixtures/mangapill_genre_ecchi.html').readAsStringSync();
    final doc = p.parse(html);
    final cards = doc.querySelectorAll('.grid.justify-end.gap-3 > div');
    final btns = doc.querySelectorAll('a.btn.btn-sm');

    debugPrint('Cards: ${cards.length}');
    debugPrint('hasNext: ${btns.any((b) => b.text.trim() == "Next")}');
    debugPrint(
        'Next href: ${btns.where((b) => b.text.trim() == "Next").firstOrNull?.attributes['href']}');
  });
}
