import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nhasixapp/data/repositories/ai/mosaic_builder.dart';
import 'package:nhasixapp/domain/entities/ai_translation.dart';

void main() {
  test('buildMosaic produces non-empty JPEG with labels for each box',
      () {
    // 100x100 white test page
    final page = img.Image(width: 100, height: 100);
    img.fill(page, color: img.ColorRgb8(255, 255, 255));
    final pageBytes = Uint8List.fromList(img.encodeJpg(page, quality: 90));

    final builder = MosaicBuilder();
    final mosaic = builder.buildMosaic(pageBytes, [
      const BubbleBoxLike(10, 10, 30, 20),
      const BubbleBoxLike(50, 50, 25, 15),
    ]);

    expect(mosaic, isNotEmpty);
    expect(mosaic.length, lessThan(2 * 1024 * 1024)); // < 2MB cap

    // Decode mosaic and verify label count via width/height sanity
    final decoded = img.decodeImage(mosaic);
    expect(decoded, isNotNull);
    // 2 chips of 30x20 + 25x15 scaled 2x + gaps + label area
    expect(decoded!.height, greaterThan(60));
    expect(decoded.width, greaterThan(56)); // label column
  });

  test('buildMosaic throws on empty bubble list', () {
    final page = img.Image(width: 50, height: 50);
    final bytes = Uint8List.fromList(img.encodeJpg(page, quality: 90));
    final builder = MosaicBuilder();
    expect(
      () => builder.buildMosaic(bytes, const []),
      throwsArgumentError,
    );
  });
}
