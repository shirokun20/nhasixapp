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
      primaryColor: ColorsConst.primaryColor,
      scaffoldBackgroundColor: ColorsConst.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorsConst.surface,
        foregroundColor: ColorsConst.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: ColorsConst.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(
            color: ColorsConst.borderDefault,
            width: 1,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: ColorsConst.surface,
        textColor: ColorsConst.darkTextPrimary,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorsConst.primaryColor,
        brightness: Brightness.dark,
        surface: ColorsConst.surface,
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
      themeMode.hashCode ^
      currentTheme.hashCode ^
      lastUpdated.hashCode;
}
