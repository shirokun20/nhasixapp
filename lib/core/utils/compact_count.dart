/// Compact download counts for the UI.
///
/// One decimal with a `k`/`M` suffix, trailing `.0` trimmed:
///   642   -> "642"
///   1284  -> "1.3k"
///   1000  -> "1k"
///   2148  -> "2.1k"
///   1500000 -> "1.5M"
String formatCompactCount(int value) {
  if (value < 1000) return '$value';
  if (value < 1000000) return '${_oneDecimal(value / 1000)}k';
  return '${_oneDecimal(value / 1000000)}M';
}

String _oneDecimal(double value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
