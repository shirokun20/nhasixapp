class TitleParserUtils {
  /// Extracts the base title from a full chapter/volume title.
  /// Removes trailing markers like "Chapter 1", "Vol 2", "Part 3", etc.
  static String getBaseTitle(String fullTitle) {
    if (fullTitle.isEmpty) return fullTitle;

    // Regex to match common chapter/volume markers and any trailing text/numbers after them
    // Matches: [space or dash] followed by (chapter, ch, part, vol, episode, ep, hen, 編, #)
    // followed by numbers, optionally with decimals or other text until the end of the string
    const pattern =
        r'[\s\-]*(?:chapter\b|ch\.|part\b|vol\.|volume\b|episode\b|ep\.|hen\b|編|#).*$';
    final regExp = RegExp(pattern, caseSensitive: false);
    String baseTitle = fullTitle.replaceAll(regExp, '').trim();

    // If the title still ends with a number (e.g. "One Piece 1044"), try to strip trailing numbers
    // only if there is a space before the number, to avoid stripping numbers that are part of the name like "Mob Psycho 100"
    // We'll use a conservative regex for trailing standalone numbers
    final trailingNumberRegExp = RegExp(r'\s+\d+(?:\.\d+)?$');
    final withoutTrailingNum =
        baseTitle.replaceAll(trailingNumberRegExp, '').trim();

    // Only use the version without trailing number if it's not empty
    if (withoutTrailingNum.isNotEmpty) {
      baseTitle = withoutTrailingNum;
    }

    // Clean up trailing dashes or colons
    baseTitle = baseTitle.replaceAll(RegExp(r'[\s\-:]+$'), '').trim();

    return baseTitle.isNotEmpty ? baseTitle : fullTitle;
  }
}
