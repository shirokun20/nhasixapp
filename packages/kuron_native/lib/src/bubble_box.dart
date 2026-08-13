import 'dart:ui';

/// Manga speech bubble bounding box detected by the on-device ONNX model.
class BubbleBox {
  const BubbleBox({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    this.confidence = 1.0,
    this.shape,
    this.kind,
    this.tail,
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

  /// Bubble outline polygon in original image pixel coords ([[x,y],...]).
  /// Null = box-only fallback (rounded-rect render).
  final List<List<int>>? shape;

  /// Bubble class name: "balloon" / "text" / "frame" / "unknown".
  final String? kind;

  /// User-drawn tail polygon [[x,y],...] in original image pixels.
  /// Null = no tail. Merged with [shape] at render time.
  final List<List<int>>? tail;

  int get cx => x + w ~/ 2;
  int get cy => y + h ~/ 2;

  /// Stable int key for matching a translated bubble back to this detection
  /// box (same rect, int coords). Used to re-attach shape post-AI.
  int get rectKey => Object.hash(x, y, w, h);

  /// Polygon as [Offset]s (orig px), or null when no shape.
  List<Offset>? get shapeOffsets => shape
      ?.map((p) => Offset(p[0].toDouble(), p[1].toDouble()))
      .toList();

  BubbleBox copyWith({
    int? x,
    int? y,
    int? w,
    int? h,
    double? confidence,
    List<List<int>>? shape,
    String? kind,
    List<List<int>>? tail,
    bool clearTail = false,
  }) {
    return BubbleBox(
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      confidence: confidence ?? this.confidence,
      shape: shape ?? this.shape,
      kind: kind ?? this.kind,
      tail: clearTail ? null : (tail ?? this.tail),
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'confidence': confidence,
        if (shape != null) 'shape': shape,
        if (kind != null) 'kind': kind,
        if (tail != null) 'tail': tail,
      };

  factory BubbleBox.fromJson(Map<String, dynamic> json) => BubbleBox(
        x: (json['x'] as num).toInt(),
        y: (json['y'] as num).toInt(),
        w: (json['w'] as num).toInt(),
        h: (json['h'] as num).toInt(),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        shape: (json['shape'] as List<dynamic>?)
            ?.map((p) => (p as List<dynamic>).map((e) => (e as num).toInt()).toList())
            .toList(),
        kind: json['kind'] as String?,
        tail: (json['tail'] as List<dynamic>?)
            ?.map((p) => (p as List<dynamic>).map((e) => (e as num).toInt()).toList())
            .toList(),
      );

  factory BubbleBox.fromMap(Map<String, dynamic> map) => BubbleBox.fromJson(map);

  @override
  String toString() =>
      'BubbleBox(x: $x, y: $y, w: $w, h: $h, confidence: $confidence, kind: $kind, shape: ${shape?.length ?? 0}pts)';
}