import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/colors_const.dart';
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
        return _createDarkTheme(); // Default to dark
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

  /// Create light theme
  ThemeData _createLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: ColorsConst.primaryColor,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[50],
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.white,
        textColor: Colors.black,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorsConst.primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  /// Create dark theme
  ThemeData _createDarkTheme() {
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
      cardTheme: CardThemeData(
        color: ColorsConst.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
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
        background: ColorsConst.background,
      ),
      useMaterial3: true,
    );
  }

  /// Create AMOLED theme (pure black)
  ThemeData _createAmoledTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: ColorsConst.primaryColor,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111111),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: Color(0xFF333333),
            width: 1,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Color(0xFF111111),
        textColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: ColorsConst.primaryColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF111111),
        background: Colors.black,
      ),
      useMaterial3: true,
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
