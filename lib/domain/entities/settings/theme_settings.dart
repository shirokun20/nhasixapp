/// Theme-related settings entities
/// Extracted from settings_repository.dart
library;

/// Theme settings configuration
class ThemeSettings {
  const ThemeSettings({
    required this.currentTheme,
    required this.useSystemTheme,
    required this.customThemes,
    this.accentColor,
    this.useAmoledDark = false,
  });

  final String currentTheme;
  final bool useSystemTheme;
  final List<String> customThemes;
  final String? accentColor;
  final bool useAmoledDark;

  ThemeSettings copyWith({
    String? currentTheme,
    bool? useSystemTheme,
    List<String>? customThemes,
    String? accentColor,
    bool? useAmoledDark,
  }) {
    return ThemeSettings(
      currentTheme: currentTheme ?? this.currentTheme,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      customThemes: customThemes ?? this.customThemes,
      accentColor: accentColor ?? this.accentColor,
      useAmoledDark: useAmoledDark ?? this.useAmoledDark,
    );
  }
}

/// Theme option
class ThemeOption {
  const ThemeOption({
    required this.id,
    required this.name,
    required this.description,
    required this.previewColors,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String description;
  final List<String> previewColors;
  final bool isCustom;
}

/// Custom theme configuration
class CustomTheme {
  const CustomTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String surfaceColor;
  final DateTime createdAt;
}
