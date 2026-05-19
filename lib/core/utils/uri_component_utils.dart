import 'dart:convert';

/// Utilities for decoding route/query components without crashing on malformed
/// percent sequences.
class UriComponentUtils {
  const UriComponentUtils._();

  /// Decodes valid percent-encoded sequences while preserving malformed input.
  ///
  /// This is intentionally tolerant because some route parameters can already
  /// arrive pre-decoded from GoRouter, which means a literal `%` would make
  /// [Uri.decodeComponent] throw even though the original content ID is valid.
  static String safeDecode(String value) {
    if (value.isEmpty || !value.contains('%')) {
      return value;
    }

    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return _decodePercentEncodedSegments(value) ?? value;
    }
  }

  static String? _decodePercentEncodedSegments(String value) {
    final buffer = StringBuffer();
    var index = 0;

    while (index < value.length) {
      if (value.codeUnitAt(index) != 0x25) {
        buffer.writeCharCode(value.codeUnitAt(index));
        index += 1;
        continue;
      }

      final bytes = <int>[];
      var cursor = index;

      while (cursor + 2 < value.length && value.codeUnitAt(cursor) == 0x25) {
        final hex = value.substring(cursor + 1, cursor + 3);
        final byte = int.tryParse(hex, radix: 16);
        if (byte == null) {
          break;
        }
        bytes.add(byte);
        cursor += 3;
      }

      if (bytes.isEmpty) {
        return null;
      }

      try {
        buffer.write(utf8.decode(bytes));
      } on FormatException {
        return null;
      }

      index = cursor;
    }

    return buffer.toString();
  }
}
