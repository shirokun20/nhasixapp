import 'dart:ui';

/// True when [points] (a closed polygon, e.g. a bubble/frame outline in
/// screen coordinates) is a nearly perfect axis-aligned rectangle — narration
/// boxes, panel frames, and rectangular speech bubbles produced by
/// `approxPolyDP`.
///
/// Such shapes must render with STRAIGHT edges and sharp corners. Applying the
/// midpoint-quadratic-bezier smoothing used for oval bubbles turns them into
/// pill/oval shapes, which is wrong for square/rectangular frames.
///
/// Rule: shoelace polygon area vs. bounding-box area. A true rectangle fills
/// its bounding box (ratio ≈ 1.0); an oval polygon fills only ~π/4 ≈ 0.785.
/// The 0.95 threshold cleanly separates rect-like shapes from oval/jagged
/// ones, and tolerates minor approxPolyDP corner noise.
///
/// Note: only axis-aligned rectangles are detected — a square rotated 45°
/// (diamond) keeps the smooth path. Panel frames in manga are axis-aligned,
/// so this covers the real-world cases.
bool isRectLikePolygon(List<Offset> points) {
  if (points.length < 3) return false;
  final first = points.first;
  var left = first.dx;
  var right = first.dx;
  var top = first.dy;
  var bottom = first.dy;
  var doubleArea = 0.0;
  const minSize = 4.0; // ignore degenerate slivers — keep smoothing
  for (var i = 0; i < points.length; i++) {
    final p = points[i];
    if (p.dx < left) left = p.dx;
    if (p.dx > right) right = p.dx;
    if (p.dy < top) top = p.dy;
    if (p.dy > bottom) bottom = p.dy;
    final q = points[(i + 1) % points.length];
    doubleArea += p.dx * q.dy - q.dx * p.dy;
  }
  final boxW = right - left;
  final boxH = bottom - top;
  if (boxW < minSize || boxH < minSize) return false;
  final area = doubleArea.abs() / 2;
  if (area <= 0) return false;
  return area / (boxW * boxH) >= 0.95;
}
