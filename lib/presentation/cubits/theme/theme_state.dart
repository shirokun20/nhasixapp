part of 'theme_cubit.dart';

/// State for theme management
class ThemeState {
  const ThemeState({
    required this.themeData,
    required this.themeMode,
    required this.currentTheme,
    required this.lastUpdated,
  });

  final ThemeData themeData;
  final ThemeMode themeMode;
  final String currentTheme;
  final DateTime lastUpdated;

  /// Initial state with default dark theme
  factory ThemeState.initial() {
    return ThemeState(
      themeData: _createDefaultDarkTheme(),
      themeMode: ThemeMode.dark,
      currentTheme: 'dark',
      lastUpdated: DateTime.now(),
    );
  }

  /// Create default dark theme data
  static ThemeData _createDefaultDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.brandCoral,
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(
            color: AppColors.darkBorder,
            width: 1,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.darkCard,
        textColor: AppColors.darkText,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandCoral,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        onSurfaceVariant: AppColors.darkTextSub,
      ),
      useMaterial3: true,
    );
  }

  /// Copy with new values
  ThemeState copyWith({
    ThemeData? themeData,
    ThemeMode? themeMode,
    String? currentTheme,
    DateTime? lastUpdated,
  }) {
    return ThemeState(
      themeData: themeData ?? this.themeData,
      themeMode: themeMode ?? this.themeMode,
      currentTheme: currentTheme ?? this.currentTheme,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          currentTheme == other.currentTheme &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode =>
      themeMode.hashCode ^ currentTheme.hashCode ^ lastUpdated.hashCode;
}
