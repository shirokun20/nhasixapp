import 'dart:convert';

import 'package:logger/logger.dart';

import '../../../domain/repositories/ai_translation_repositories.dart';

/// Hardened extraction of model-returned JSON.
///
/// Weak/small vision models often wrap the answer in markdown fences, echo
/// the prompt's `...` example marker, leave trailing commas, or prepend
/// chatter containing braces — any of which kills a naive
/// `indexOf('{')`/`lastIndexOf('}')` + single `jsonDecode` attempt and fails
/// the whole page. This parser tries candidates in order (raw first, so
/// legitimate content is never mutated) and only throws a user-actionable
/// error when nothing decodes.
class ModelJsonParser {
  ModelJsonParser._();

  static final RegExp _ellipsisRegExp = RegExp(r'\s*\.\.\.\s*,?');
  static final RegExp _trailingCommaRegExp = RegExp(r',(\s*[}\]])');

  /// Whole-value placeholder: the entire translation is one `<...>` token.
  /// Whole-match (not contains) so legit bracketed text is never mistaken
  /// for an echoed template.
  static final RegExp _placeholderRegExp = RegExp(r'^<[^<>]*>$');

  /// Parses a mosaic-style JSON object (`{"1": {...}, ...}`) from [content].
  ///
  /// When [logger] is given, records which candidate decoded — index 0 with
  /// no repair is the happy path; anything else means the model returned
  /// sloppy JSON (fences/ellipsis/trailing commas/chatter).
  static Map<String, dynamic> parseMosaicJson(
    String content, {
    Logger? logger,
    String tag = '',
  }) {
    final candidates = _candidates(content, '{', '}');
    for (var i = 0; i < candidates.length; i++) {
      try {
        final decoded = jsonDecode(candidates[i]);
        if (decoded is Map && _looksLikeMosaicRoot(decoded)) {
          logger?.d(
              '$tag: mosaic JSON decoded via candidate #$i${i == 0 ? '' : ' (repaired)'}');
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // try next candidate
      }
    }
    logger?.w('$tag: mosaic JSON unrecoverable '
        '(${candidates.length} candidates, ${content.length} chars)');
    throw const AiTranslationException(
      'Model returned an unusable response. Retry, or switch to a stronger vision model.',
    );
  }

  /// A mosaic root is empty or keyed by bubble numbers. Without this check,
  /// a nested-but-valid object (e.g. `{"original": ...}`) would decode first
  /// and shadow the real root.
  static bool _looksLikeMosaicRoot(Map<dynamic, dynamic> decoded) {
    if (decoded.isEmpty) return true;
    return decoded.keys.any((k) => k is String && int.tryParse(k) != null);
  }

  /// Parses a full-image-style JSON array (`[{...}, ...]`) from [content].
  static List<dynamic> parseJsonArray(
    String content, {
    Logger? logger,
    String tag = '',
  }) {
    final candidates = _candidates(content, '[', ']');
    for (var i = 0; i < candidates.length; i++) {
      try {
        final decoded = jsonDecode(candidates[i]);
        if (decoded is List) {
          logger?.d(
              '$tag: coordinate array decoded via candidate #$i${i == 0 ? '' : ' (repaired)'}');
          return decoded;
        }
      } catch (_) {
        // try next candidate
      }
    }
    logger?.w('$tag: coordinate array unrecoverable '
        '(${candidates.length} candidates, ${content.length} chars)');
    throw const AiTranslationException(
      'Model returned an unusable response. Retry, or switch to a stronger vision model.',
    );
  }

  /// Single-line truncated preview for logs. Never logs full content —
  /// responses may contain user reading material.
  static String preview(String text, [int maxChars = 500]) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.length <= maxChars) return flat;
    return '${flat.substring(0, maxChars)}…';
  }

  /// True when [value] looks like an echoed template placeholder rather
  /// than a real translation: `<...>` tokens (any language, e.g.
  /// `<terjemahan>`, `<bacaan latin>`) or a bare `...`.
  static bool looksLikePlaceholder(String value) {
    final trimmed = value.trim();
    if (trimmed == '...') return true;
    return _placeholderRegExp.hasMatch(trimmed);
  }

  static List<String> _candidates(String content, String open, String close) {
    final text = _stripFences(content.trim());
    final out = <String>[];
    void add(String? s) {
      if (s != null && s.isNotEmpty && !out.contains(s)) out.add(s);
    }

    // Raw candidates first: balanced extraction from every opener, then the
    // legacy naive first-opener/last-closer span.
    for (final balanced in _balancedCandidates(text, open, close)) {
      add(balanced);
    }
    final start = text.indexOf(open);
    final end = text.lastIndexOf(close);
    if (start != -1 && end > start) add(text.substring(start, end + 1));

    // Repairs last: only reached when raw decoding already failed, so
    // legitimate content (e.g. "Wait...") is never mutated on the happy path.
    for (final base in List<String>.of(out)) {
      add(_removeEllipsis(base));
      add(_removeTrailingCommas(_removeEllipsis(base)));
    }
    return out;
  }

  static List<String> _balancedCandidates(
      String text, String open, String close) {
    final out = <String>[];
    var from = 0;
    while (out.length < 8) {
      final start = text.indexOf(open, from);
      if (start == -1) break;
      final extracted = _extractBalanced(text, start, open, close);
      if (extracted != null && !out.contains(extracted)) out.add(extracted);
      from = start + 1;
    }
    return out;
  }

  /// Extracts the balanced [open]...[close] span starting at [start],
  /// ignoring brackets inside double-quoted strings. Null when unbalanced
  /// (e.g. truncated response).
  static String? _extractBalanced(
      String text, int start, String open, String close) {
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < text.length; i++) {
      final ch = text[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (ch == r'\') {
          escaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == open) {
        depth++;
      } else if (ch == close) {
        depth--;
        if (depth == 0) return text.substring(start, i + 1);
      }
    }
    return null;
  }

  static String _stripFences(String text) {
    var t = text;
    if (t.startsWith('```')) {
      final firstNl = t.indexOf('\n');
      if (firstNl != -1) t = t.substring(firstNl + 1);
      final endFence = t.lastIndexOf('```');
      if (endFence != -1) t = t.substring(0, endFence);
      t = t.trim();
    }
    return t;
  }

  static String _removeEllipsis(String text) =>
      text.replaceAll(_ellipsisRegExp, '');

  static String _removeTrailingCommas(String text) =>
      text.replaceAllMapped(_trailingCommaRegExp, (m) => m.group(1)!);
}
