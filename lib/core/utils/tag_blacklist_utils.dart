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
    return sanitizeEntries(rawInput.split(RegExp(r'[,;\n]')));
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
