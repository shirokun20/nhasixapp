import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors_const.dart' show AppColors;
import '../../../core/constants/design_tokens.dart';
import '../settings/settings_cubit.dart';

part 'theme_state.dart';

/// Cubit for managing app theme changes
/// Listens to SettingsCubit and provides reactive ThemeData
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({
    required SettingsCubit settingsCubit,
    required Logger logger,
  })  : _settingsCubit = settingsCubit,
        _logger = logger,
        super(ThemeState.initial()) {
    // Listen to settings changes
    _settingsSubscription = _settingsCubit.stream.listen(_onSettingsChanged);

    // Initialize with current settings
    _updateThemeFromSettings(_settingsCubit.state);
  }

  final SettingsCubit _settingsCubit;
  final Logger _logger;
  late final StreamSubscription _settingsSubscription;

  /// Update theme when settings change
  void _onSettingsChanged(SettingsState settingsState) {
    _updateThemeFromSettings(settingsState);
  }

  /// Update theme data based on settings
  void _updateThemeFromSettings(SettingsState settingsState) {
    if (settingsState is SettingsLoaded) {
      final preferences = settingsState.preferences;
      final themeData = _createThemeData(preferences.theme);

      emit(ThemeState(
        themeData: themeData,
        themeMode: _getThemeMode(preferences.theme),
        currentTheme: preferences.theme,
        lastUpdated: DateTime.now(),
      ));

      _logger.i('Theme updated to: ${preferences.theme}');
    }
  }

  /// Create ThemeData based on theme setting
  ThemeData _createThemeData(String theme) {
    switch (theme) {
      case 'light':
        return _createLightTheme();
      case 'dark':
        return _createDarkTheme();
      case 'amoled':
        return _createAmoledTheme();
      default:
        return _createDarkTheme();
    }
  }

  /// Get ThemeMode for MaterialApp
  ThemeMode _getThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
      case 'amoled':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }

  /// Create light theme - warm, elegant, inviting
  ThemeData _createLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandCoral,
        onPrimary: Colors.white,
        primaryContainer: AppColors.brandDusty,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.brandMuted,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFF5E0DE),
        onSecondaryContainer: AppColors.brandDusty,
        tertiary: AppColors.brandDusty,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFEDE0DF),
        onTertiaryContainer: AppColors.brandDusty,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightText,
        onSurfaceVariant: AppColors.lightTextSub,
        surfaceContainerHighest: AppColors.lightCard,
        outline: AppColors.lightBorder,
        outlineVariant: Color(0xFFD5D0CA),
        shadow: Colors.black26,
        scrim: Colors.black54,
        inverseSurface: AppColors.brandDark,
        onInverseSurface: AppColors.lightBg,
        inversePrimary: AppColors.brandCoral,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        foregroundColor: AppColors.lightText,
        elevation: DesignTokens.elevationNone,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: DesignTokens.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.lightSurface,
        textColor: AppColors.lightText,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        indicatorColor: AppColors.brandCoral.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.brandCoral,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: AppColors.lightTextSub,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.brandCoral);
          }
          return const IconThemeData(color: AppColors.lightTextSub);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandCoral,
        foregroundColor: Colors.white,
        elevation: DesignTokens.elevationMd,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: AppColors.brandCoral, width: 2),
        ),
      ),
    );
  }

  /// Create dark theme - deep, rich, comfortable
  ThemeData _createDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandCoral,
        onPrimary: Colors.white,
        primaryContainer: AppColors.brandDusty,
        onPrimaryContainer: Color(0xFFFFD8D4),
        secondary: AppColors.brandMuted,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF4A2A28),
        onSecondaryContainer: Color(0xFFFFD8D4),
        tertiary: AppColors.brandDusty,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF3D2022),
        onTertiaryContainer: Color(0xFFFFD8D4),
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: Color(0xFF4A1A1A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        onSurfaceVariant: AppColors.darkTextSub,
        surfaceContainerHighest: AppColors.darkCard,
        outline: AppColors.darkBorder,
        outlineVariant: Color(0xFF444450),
        shadow: Colors.black54,
        scrim: Colors.black87,
        inverseSurface: AppColors.lightBg,
        onInverseSurface: AppColors.brandDark,
        inversePrimary: AppColors.brandDusty,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.darkText,
        elevation: DesignTokens.elevationNone,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: DesignTokens.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.darkSurface,
        textColor: AppColors.darkText,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.brandCoral.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.brandCoral,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: AppColors.darkTextSub,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.brandCoral);
          }
          return const IconThemeData(color: AppColors.darkTextSub);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandCoral,
        foregroundColor: Colors.white,
        elevation: DesignTokens.elevationMd,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: AppColors.brandCoral, width: 2),
        ),
      ),
    );
  }

  /// Create AMOLED theme - pure black, vibrant coral accents
  ThemeData _createAmoledTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandCoral,
        onPrimary: Colors.white,
        primaryContainer: AppColors.brandDusty,
        onPrimaryContainer: Color(0xFFFFD8D4),
        secondary: AppColors.brandMuted,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF2A1518),
        onSecondaryContainer: Color(0xFFFFD8D4),
        tertiary: AppColors.brandDusty,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFF251214),
        onTertiaryContainer: Color(0xFFFFD8D4),
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: Color(0xFF2A0A0A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF0A0A0F),
        onSurface: Color(0xFFE8E4E0),
        onSurfaceVariant: Color(0xFF7A7570),
        surfaceContainerHighest: Color(0xFF141418),
        outline: Color(0xFF282830),
        outlineVariant: Color(0xFF1A1A22),
        shadow: Colors.black87,
        scrim: Colors.black,
        inverseSurface: AppColors.lightBg,
        onInverseSurface: AppColors.brandDark,
        inversePrimary: AppColors.brandDusty,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Color(0xFFE8E4E0),
        elevation: DesignTokens.elevationNone,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF141418),
        elevation: DesignTokens.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          side: const BorderSide(color: Color(0xFF282830), width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Color(0xFF0A0A0F),
        textColor: Color(0xFFE8E4E0),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF282830),
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.black,
        indicatorColor: AppColors.brandCoral.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.brandCoral,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: Color(0xFF7A7570),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.brandCoral);
          }
          return const IconThemeData(color: Color(0xFF7A7570));
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandCoral,
        foregroundColor: Colors.white,
        elevation: DesignTokens.elevationSm,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0A0A0F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF282830)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF282830)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          borderSide: const BorderSide(color: AppColors.brandCoral, width: 2),
        ),
      ),
    );
  }

  /// Force theme update
  void updateTheme() {
    _updateThemeFromSettings(_settingsCubit.state);
  }

  /// Get current theme name
  String? get currentTheme {
    final currentState = state;
    return currentState.currentTheme;
  }

  /// Check if current theme is dark
  bool get isDark {
    final theme = currentTheme;
    return theme == 'dark' || theme == 'amoled';
  }

  /// Check if current theme is AMOLED
  bool get isAmoled {
    return currentTheme == 'amoled';
  }

  @override
  Future<void> close() {
    _settingsSubscription.cancel();
    return super.close();
  }
}
