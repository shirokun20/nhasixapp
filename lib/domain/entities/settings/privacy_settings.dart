/// Privacy settings entities
/// Extracted from settings_repository.dart
library;

/// Privacy settings configuration
class PrivacySettings {
  const PrivacySettings({
    required this.hideFromRecents,
    required this.requireAuthentication,
    required this.blurInBackground,
    required this.incognitoMode,
    this.authenticationTimeout = 300,
  });

  final bool hideFromRecents;
  final bool requireAuthentication;
  final bool blurInBackground;
  final bool incognitoMode;
  final int authenticationTimeout;
}

/// Content filter settings
class ContentFilterSettings {
  const ContentFilterSettings({
    required this.showNsfwContent,
    required this.blacklistedTags,
    required this.whitelistedTags,
    required this.minimumRating,
    this.ageRestriction,
  });

  final bool showNsfwContent;
  final List<String> blacklistedTags;
  final List<String> whitelistedTags;
  final double minimumRating;
  final int? ageRestriction;
}
