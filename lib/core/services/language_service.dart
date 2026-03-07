import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Holds display metadata for a single language entry.
class LanguageInfo {
  final String displayName;

  /// ISO 639-1 two-letter code (e.g. "id", "en").
  final String code;

  /// Filename (without extension) of the flag SVG inside
  /// `assets/images/flags/`. Null if no flag asset exists.
  final String? flagFile;

  const LanguageInfo({
    required this.displayName,
    required this.code,
    this.flagFile,
  });

  /// Absolute asset path to the flag SVG, or null.
  String? get flagAssetPath =>
      flagFile != null ? 'assets/images/flags/$flagFile.svg' : null;

  /// Two-letter uppercase badge (e.g. "ID", "EN").
  String get badge => code.toUpperCase();
}

/// Service that loads language metadata from `assets/configs/languages.json`
/// and provides synchronous lookups after [load] completes.
///
/// Register as a lazy singleton and call [load] during app init.
class LanguageService {
  final Logger _logger;

  final Map<String, LanguageInfo> _entries = {};

  LanguageService({required Logger logger}) : _logger = logger;

  bool get isLoaded => _entries.isNotEmpty;

  /// Load and cache `assets/configs/languages.json`.
  /// Safe to call multiple times; subsequent calls are no-ops.
  Future<void> load() async {
    if (isLoaded) return;
    try {
      final raw = await rootBundle.loadString('assets/configs/languages.json');
      final parsed = json.decode(raw) as Map<String, dynamic>;
      final languages = parsed['languages'] as Map<String, dynamic>? ?? {};
      for (final entry in languages.entries) {
        final data = entry.value as Map<String, dynamic>;
        _entries[entry.key] = LanguageInfo(
          displayName: data['displayName'] as String,
          code: data['code'] as String,
          flagFile: data['flagFile'] as String?,
        );
      }
      _logger.d('LanguageService: loaded ${_entries.length} language entries');
    } catch (e) {
      _logger.e('LanguageService: failed to load languages.json', error: e);
    }
  }

  /// Resolve a language key (code or full name) to its [LanguageInfo].
  LanguageInfo? resolve(String langKey) {
    final key = langKey.toLowerCase().trim();
    if (key.isEmpty || key == 'unknown') return null;
    return _entries[key];
  }

  /// Display name for [langKey], falling back to [langKey] itself.
  String displayName(String langKey) {
    return resolve(langKey)?.displayName ?? langKey;
  }

  /// Flag asset path for [langKey], or null if no flag exists.
  String? flagAssetPath(String langKey) {
    return resolve(langKey)?.flagAssetPath;
  }

  /// Two-letter uppercase badge for [langKey].
  String badge(String langKey) {
    return resolve(langKey)?.badge ?? langKey.substring(0, 2).toUpperCase();
  }
}
