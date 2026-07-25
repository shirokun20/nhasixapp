class BubbleBox {
  final int x, y, w, h;
  final double confidence;

  const BubbleBox({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.confidence = 1.0,
  });

  int get cx => x + w ~/ 2;
  int get cy => y + h ~/ 2;

  BubbleBox copyWith({int? x, int? y, int? w, int? h, double? confidence}) {
    return BubbleBox(
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      confidence: confidence ?? this.confidence,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'confidence': confidence,
      };

  factory BubbleBox.fromJson(Map<String, dynamic> json) => BubbleBox(
        x: (json['x'] as num).toInt(),
        y: (json['y'] as num).toInt(),
        w: (json['w'] as num).toInt(),
        h: (json['h'] as num).toInt(),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      );
}
