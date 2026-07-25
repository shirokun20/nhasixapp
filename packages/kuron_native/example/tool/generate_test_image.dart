// dart run tool/generate_test_image.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const width = 800;
  const height = 1100;
  final image = img.Image(width: width, height: height);

  // White background
  img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));

  final allBubbles = <_Bubble>[];

  // Panel 1
  _drawPanel(image, 30, 30, 740, 340);
  allBubbles.addAll([_bubble(80, 80, 280, 90), _bubble(450, 100, 280, 85)]);

  // Panel 2
  _drawPanel(image, 30, 390, 740, 300);
  allBubbles.addAll([
    _bubble(120, 420, 300, 100),
    _bubble(400, 450, 280, 95),
    _bubble(160, 560, 240, 80),
  ]);

  // Panel 3
  _drawPanel(image, 30, 710, 740, 360);
  allBubbles.addAll([
    _bubble(90, 740, 300, 85),
    _bubble(400, 780, 290, 95),
    _bubble(60, 870, 280, 85),
    _bubble(420, 900, 300, 95),
  ]);

  // Panel borders
  final black = img.ColorRgba8(0, 0, 0, 255);
  img.drawRect(
    image,
    x1: 30,
    y1: 30,
    x2: 770,
    y2: 370,
    color: black,
    thickness: 2,
  );
  img.drawRect(
    image,
    x1: 30,
    y1: 390,
    x2: 770,
    y2: 690,
    color: black,
    thickness: 2,
  );
  img.drawRect(
    image,
    x1: 30,
    y1: 710,
    x2: 770,
    y2: 1070,
    color: black,
    thickness: 2,
  );

  // Bubble borders
  final blue = img.ColorRgba8(0, 100, 200, 255);
  for (final b in allBubbles) {
    img.drawRect(
      image,
      x1: b.x,
      y1: b.y,
      x2: b.x + b.w,
      y2: b.y + b.h,
      color: blue,
      thickness: 1,
    );
  }

  // Simulate "japanese text" as pixel noise inside bubbles
  final textColor = img.ColorRgba8(30, 30, 30, 255);
  for (final b in allBubbles) {
    for (var i = 0; i < 15; i++) {
      final tx = b.x + 8 + (i * 14) % (b.w - 16);
      final ty = b.y + 16 + (i ~/ 6) * 18;
      for (var s = 0; s < 5; s++) {
        img.drawPixel(image, tx + s, ty, textColor);
        img.drawPixel(image, tx + s, ty + 1, textColor);
      }
    }
  }

  // Save
  final outDir = Directory('${Directory.current.path}/assets');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final outPath = '${outDir.path}/sample_manga.jpg';
  final jpeg = img.encodeJpg(image, quality: 90);
  File(outPath).writeAsBytesSync(jpeg);
}

class _Bubble {
  final int x, y, w, h;
  const _Bubble(this.x, this.y, this.w, this.h);
}

_Bubble _bubble(int x, int y, int w, int h) => _Bubble(x, y, w, h);

void _drawPanel(img.Image image, int px, int py, int pw, int ph) {
  img.fillRect(
    image,
    x1: px + 1,
    y1: py + 1,
    x2: px + pw - 1,
    y2: py + ph - 1,
    color: img.ColorRgba8(245, 245, 245, 255),
  );
}
