class BubbleTranslation {
  final int id;
  final String original;
  String translated;
  final int x, y, w, h;

  BubbleTranslation({
    required this.id,
    required this.original,
    this.translated = '',
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  bool get isSkipped => translated == 'SKIP';
  bool get isTranslated => translated.isNotEmpty && translated != 'SKIP';

  Map<String, dynamic> toJson() => {
        'id': id,
        'original': original,
        'translated': translated,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
      };
}

class PageTranslation {
  final List<BubbleTranslation> bubbles;
  final String detectedLang;
  final bool usedFallback;
  final String? error;

  PageTranslation({
    required this.bubbles,
    this.detectedLang = 'ja',
    this.usedFallback = false,
    this.error,
  });

  bool get hasError => error != null;

  Map<String, dynamic> toJson() => {
        'bubbles': bubbles.map((b) => b.toJson()).toList(),
        'detectedLang': detectedLang,
        'usedFallback': usedFallback,
      };
}
