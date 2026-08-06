/// Manga speech bubble bounding box detected by the on-device ONNX model.
class BubbleBox {
  const BubbleBox({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.confidence = 1.0,
  });

  /// Top-left X in original image pixel coordinates.
  final int x;

  /// Top-left Y in original image pixel coordinates.
  final int y;

  /// Width in pixels.
  final int w;

  /// Height in pixels.
  final int h;

  /// Detection confidence (0..1). Manual bubbles default to 1.0.
  final double confidence;

  int get cx => x + w ~/ 2;
  int get cy => y + h ~/ 2;

  BubbleBox copyWith({
    int? x,
    int? y,
    int? w,
    int? h,
    double? confidence,
  }) {
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

  factory BubbleBox.fromMap(Map<String, dynamic> map) => BubbleBox.fromJson(map);

  @override
  String toString() =>
      'BubbleBox(x: $x, y: $y, w: $w, h: $h, confidence: $confidence)';
}
