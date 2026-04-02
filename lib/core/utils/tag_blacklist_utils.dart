import 'dart:convert';

import 'package:kuron_core/kuron_core.dart';

class TagBlacklistUtils {
  const TagBlacklistUtils._();

  static String normalizeEntry(String raw) {
    var value = raw.trim().toLowerCase();
    if (value.startsWith('#') && int.tryParse(value.substring(1)) != null) {
      value = value.substring(1);
    }

    return value.replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<String> sanitizeEntries(Iterable<String> entries) {
    final ordered = <String>{};
    for (final entry in entries) {
      final normalized = normalizeEntry(entry);
      if (normalized.isNotEmpty) {
        ordered.add(normalized);
      }
    }

    return ordered.toList(growable: false);
  }

  static List<String> parseManualEntries(String rawInput) {
    final raw = rawInput.trim();
    if (raw.isEmpty) {
      return const [];
    }

    final entries = <String>[];

    // Support pasting API payloads like {"tag_ids":[149646,...]} or [149646,...].
    entries.addAll(_extractIdsFromJsonPayload(raw));

    for (final chunk in raw.split(RegExp(r'[,;\n]'))) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final normalizedPrefixedId = _normalizePrefixedId(trimmed);
      if (normalizedPrefixedId != null) {
        entries.add(normalizedPrefixedId);
        continue;
      }

      entries.add(trimmed);
    }

    return sanitizeEntries(entries);
  }

  static List<String> _extractIdsFromJsonPayload(String rawInput) {
    try {
      final decoded = jsonDecode(rawInput);

      if (decoded is List) {
        return decoded
            .whereType<num>()
            .map((entry) => entry.toInt().toString())
            .toList(growable: false);
      }

      if (decoded is Map) {
        final tagIds =
            decoded['tag_ids'] ?? decoded['tagIds'] ?? decoded['ids'];
        if (tagIds is List) {
          return tagIds
              .whereType<num>()
              .map((entry) => entry.toInt().toString())
              .toList(growable: false);
        }
      }
    } catch (_) {
      // Not JSON payload; continue with regular parsing.
    }

    return const [];
  }

  static String? _normalizePrefixedId(String value) {
    final lowered = value.trim().toLowerCase();
    final match =
        RegExp(r'^(?:id|tag_id|tagid|tag):\s*(\d+)$').firstMatch(lowered);
    if (match == null) {
      return null;
    }

    return match.group(1);
  }

  static List<String> mergeEntries(
    Iterable<String> localEntries,
    Iterable<String> onlineEntries,
  ) {
    return sanitizeEntries([
      ...localEntries,
      ...onlineEntries,
    ]);
  }

  static bool isContentBlacklisted(
    Content content,
    Iterable<String> blacklistEntries,
  ) {
    final normalizedBlacklist = sanitizeEntries(blacklistEntries);
    if (normalizedBlacklist.isEmpty) {
      return false;
    }

    final tokens = buildContentTokens(content);
    return normalizedBlacklist.any(tokens.contains);
  }

  static Set<String> buildContentTokens(Content content) {
    final tokens = <String>{};

    // Support numeric blacklist entries that refer to gallery/content IDs.
    _addToken(tokens, content.id);
    _addToken(tokens, 'gallery:${content.id}');

    for (final tag in content.tags) {
      _addTagTokens(tokens, tag);
    }

    _addTypedTokens(tokens, 'artist', content.artists);
    _addTypedTokens(tokens, 'character', content.characters);
    _addTypedTokens(tokens, 'parody', content.parodies);
    _addTypedTokens(tokens, 'group', content.groups);

    if (content.language.trim().isNotEmpty) {
      _addToken(tokens, content.language);
      _addToken(tokens, 'language:${content.language}');
    }

    return tokens;
  }

  static void _addTypedTokens(
    Set<String> tokens,
    String type,
    Iterable<String> values,
  ) {
    for (final value in values) {
      _addToken(tokens, value);
      _addToken(tokens, '$type:$value');
    }
  }

  static void _addTagTokens(Set<String> tokens, Tag tag) {
    _addToken(tokens, tag.name);
    _addToken(tokens, '${tag.type}:${tag.name}');

    if (tag.id > 0) {
      _addToken(tokens, tag.id.toString());
      _addToken(tokens, '${tag.type}:${tag.id}');
    }

    final slug = tag.slug?.trim();
    if (slug != null && slug.isNotEmpty) {
      _addToken(tokens, slug);
      _addToken(tokens, slug.replaceAll('-', ' '));
      _addToken(tokens, '${tag.type}:$slug');
      _addToken(tokens, '${tag.type}:${slug.replaceAll('-', ' ')}');
    }
  }

  static void _addToken(Set<String> tokens, String raw) {
    final normalized = normalizeEntry(raw);
    if (normalized.isNotEmpty) {
      tokens.add(normalized);
    }
  }
}
