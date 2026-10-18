import 'package:nhasixapp/core/config/config_models.dart';

/// True if a parameter name or queryParam indicates it is an included-tag field.
bool isIncludedTagField(String name, SearchFormFieldConfig field) {
  final lowerName = name.toLowerCase();
  final lowerQueryParam = (field.queryParam ?? '').toLowerCase();
  return lowerName.contains('included') ||
      lowerQueryParam.contains('includedtags');
}

/// True if a parameter name or queryParam indicates it is an excluded-tag field.
bool isExcludedTagField(String name, SearchFormFieldConfig field) {
  final lowerName = name.toLowerCase();
  final lowerQueryParam = (field.queryParam ?? '').toLowerCase();
  return lowerName.contains('excluded') ||
      lowerQueryParam.contains('excludedtags');
}

/// Checks if a field should be treated as a multi-select picker field.
bool isPickerField(
  String name,
  SearchFormFieldConfig field,
  Map<String, dynamic>? rawField,
) {
  if (field.type != 'tag') return false;
  final ui = rawField?['ui'];
  if (ui is Map<String, dynamic>) {
    return (ui['selector'] as String?) == 'picker' &&
        (ui['multi'] as bool? ?? false);
  }
  return false;
}

/// Checks if a field should be treated as a tag-chips input field.
bool isTagChipsField(
  String name,
  SearchFormFieldConfig field,
  Map<String, dynamic>? rawField,
) {
  if (field.type != 'tag') return false;
  final ui = rawField?['ui'];
  if (ui is Map<String, dynamic>) {
    return (ui['selector'] as String?) == 'chips';
  }
  return false;
}

/// Checks if an excluded picker field should be hidden because it is combined with an included picker.
bool shouldHideBecauseCombinedPicker({
  required String name,
  required SearchFormFieldConfig field,
  required SearchFormConfig config,
  required Map<String, dynamic>? Function(String name) rawFieldConfig,
}) {
  if (!isPickerField(name, field, rawFieldConfig(name))) return false;
  if (!isExcludedTagField(name, field)) return false;
  for (final entry in config.params.entries) {
    if (isIncludedTagField(entry.key, entry.value)) {
      return true;
    }
  }
  return false;
}

/// Formats a single value according to the raw field config (prefix, suffix, transform, quoting).
String formatFieldValue(Map<String, dynamic>? rawField, String value) {
  var result = value.trim();
  if (result.isEmpty) return result;

  final transform = (rawField?['transform'] as String? ?? '').trim();
  if (transform == 'lowercase') {
    result = result.toLowerCase();
  } else if (transform == 'uppercase') {
    result = result.toUpperCase();
  } else if (transform == 'spaceToPlus') {
    result = result.replaceAll(' ', '+');
  }

  final quoteIfContainsSpace = rawField?['quoteIfContainsSpace'] as bool?;
  if (quoteIfContainsSpace == true &&
      result.contains(' ') &&
      !result.startsWith('"') &&
      !result.endsWith('"')) {
    result = '"$result"';
  }

  final valuePrefix = (rawField?['valuePrefix'] as String? ?? '').trim();
  final valueSuffix = (rawField?['valueSuffix'] as String? ?? '').trim();
  if (valuePrefix.isNotEmpty) {
    result = '$valuePrefix$result';
  }
  if (valueSuffix.isNotEmpty) {
    result = '$result$valueSuffix';
  }

  return result;
}

/// Splits raw text into individual values (e.g. comma- or newline-separated).
List<String> splitFieldInput(
  Map<String, dynamic>? rawField,
  String rawValue,
  String fieldType,
) {
  final value = rawValue.trim();
  if (value.isEmpty) return const <String>[];

  final multiInput = rawField?['multiInput'] as bool? ?? false;
  final shouldSplit = fieldType == 'tag' || multiInput;
  if (!shouldSplit) return <String>[value];

  return value
      .split(RegExp(r'[\n,]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Strips prefix/suffix/quotes from a token to extract the raw value.
String? extractFieldCoreFromToken(
  String token,
  Map<String, dynamic>? rawField,
) {
  var current = token.trim();
  if (current.isEmpty) return null;

  final prefix = (rawField?['valuePrefix'] as String? ?? '').trim();
  final suffix = (rawField?['valueSuffix'] as String? ?? '').trim();

  if (prefix.isNotEmpty) {
    if (!current.startsWith(prefix)) return null;
    current = current.substring(prefix.length);
  }

  if (suffix.isNotEmpty) {
    if (!current.endsWith(suffix)) return null;
    current = current.substring(0, current.length - suffix.length);
  }

  if (current.length >= 2 &&
      current.startsWith('"') &&
      current.endsWith('"')) {
    current = current.substring(1, current.length - 1);
  }

  return current.trim().isEmpty ? null : current.trim();
}

/// Tokenizes a query expression respecting double quotes.
List<String> tokenizeQueryExpression(String expression) {
  final tokens = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;

  for (final rune in expression.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == '"') {
      inQuotes = !inQuotes;
      buffer.write(ch);
      continue;
    }

    if (!inQuotes && ch.trim().isEmpty) {
      final token = buffer.toString().trim();
      if (token.isNotEmpty) tokens.add(token);
      buffer.clear();
      continue;
    }

    buffer.write(ch);
  }

  final last = buffer.toString().trim();
  if (last.isNotEmpty) tokens.add(last);

  return tokens;
}

/// Parses a query string like `q=tag1&sort=recent` into a map of param to list of values.
Map<String, List<String>> parseRaw(String raw) {
  final result = <String, List<String>>{};
  for (final pair in raw.split('&')) {
    if (pair.isEmpty) continue;
    final idx = pair.indexOf('=');
    if (idx < 0) continue;
    final k = Uri.decodeComponent(pair.substring(0, idx));
    final v = Uri.decodeComponent(pair.substring(idx + 1));
    (result[k] ??= []).add(v);
  }
  return result;
}

/// Restores joined parameter groups (e.g. space-joined query tokens) to individual fields.
void restoreJoinedParamGroup({
  required String queryParam,
  required String joinedValue,
  required List<MapEntry<String, SearchFormFieldConfig>> fields,
  required Map<String, dynamic>? Function(String name) rawFieldConfig,
  required void Function(
    String name,
    SearchFormFieldConfig field,
    List<String> values,
  ) setRestoredFieldValue,
}) {
  final tokens = tokenizeQueryExpression(joinedValue);
  final consumed = List<bool>.filled(tokens.length, false);

  for (final entry in fields) {
    final name = entry.key;
    final field = entry.value;
    final rawField = rawFieldConfig(name);

    if (isPickerField(name, field, rawField)) continue;

    final hasAffix =
        ((rawField?['valuePrefix'] as String?)?.isNotEmpty ?? false) ||
            ((rawField?['valueSuffix'] as String?)?.isNotEmpty ?? false);
    if (!hasAffix) continue;

    final matched = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      if (consumed[i]) continue;
      final extracted = extractFieldCoreFromToken(tokens[i], rawField);
      if (extracted == null) continue;
      matched.add(extracted);
      consumed[i] = true;
    }

    if (matched.isNotEmpty) {
      setRestoredFieldValue(name, field, matched);
    }
  }

  final leftovers = <String>[];
  for (var i = 0; i < tokens.length; i++) {
    if (!consumed[i]) leftovers.add(tokens[i]);
  }

  if (leftovers.isEmpty) return;

  MapEntry<String, SearchFormFieldConfig>? fallback;
  for (final entry in fields) {
    final name = entry.key;
    final field = entry.value;
    final rawField = rawFieldConfig(name);
    if (isPickerField(name, field, rawField)) continue;
    if (field.type != 'text' && field.type != 'tag') continue;

    final hasAffix =
        ((rawField?['valuePrefix'] as String?)?.isNotEmpty ?? false) ||
            ((rawField?['valueSuffix'] as String?)?.isNotEmpty ?? false);
    if (!hasAffix) {
      if (name == 'query') {
        fallback = entry;
        break;
      }
      fallback ??= entry;
    }
  }

  if (fallback != null) {
    setRestoredFieldValue(
      fallback.key,
      fallback.value,
      <String>[leftovers.join(' ')],
    );
  }
}
